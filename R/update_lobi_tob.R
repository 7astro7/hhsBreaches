
# adds indicator variables for discretized type_of_breach and 
# location_of_breached_information to data_breach table in hhs 
# database if they aren't present and assigns all rows based on 
# presence of discrete value in type_of_breach or location_of_breached_information

library(DBI)
library(stringr)
source("dbc.R")
source("discretize.R")

getData = function(query_string) {
#   queries the database using query_string and returns fetched rows 
#   using connection creator function from dbc.R 

#   Parameters 
#   ----------
#   query_string: a string assigned the SQL query to pass as input 
#       to dbSendQuery() and any rows for which will be returned

#   Returns
#   -------
#   tibble
#       a tibble assigned the requested rows 

    conn = getPGDBConn()
    query = conn %>% DBI::dbSendQuery(query_string)
    data = DBI::dbFetch(query) %>% as_tibble()
    query %>% DBI::dbClearResult()
    conn %>% DBI::dbDisconnect()
    return (data)
}

cleanDiscretizedValues = function(discretized_vals) {
#   lobi location_of_breached_information or tob type_of_breach    
#   discretized values devoid of slashes and whitespace 

#   Parameters
#   ----------
#   discretized_vals: vector of type_of_breach or 
#       location_of_breached_information that may contain slashes and 
#       whitespace

#   Returns: 
#   --------
#   vector    
#       discretized_vals vector with underscores replacing whitespace and 
#       in cases where there's a string with a slash, only characters 
#       preceding the slash 

    # an index holds TRUE if the discretized_val is NA 
    # cast as factor because NA will be the string 'NA' if not 
    # and therefore won't be detected by a call to is.na()
    absent_string = as.factor(discretized_vals) %>% is.na()

    # discretized_vals drops absent / NA values 
    discretized_vals = discretized_vals[!absent_string] %>% as.character()

    slash_present = discretized_vals %>% lapply(str_detect, "/") %>% unlist()

    clean_discretized_vals = discretized_vals[!slash_present] 
    slash_present = discretized_vals[slash_present] 
    slash_present = slash_present %>% str_split("/") 
    for (i in 1:length(slash_present)) {
        slash_present[i] = slash_present[[i]][1]
        clean_discretized_vals[length(clean_discretized_vals) + 1] = slash_present[i]
    }
    clean_discretized_vals = clean_discretized_vals %>% str_replace_all(" ", "_")
    # significant:: explictly changes 'other' in either tob or lobi to 'unknown'
    for (i in 1:length(clean_discretized_vals)) {
        if (clean_discretized_vals[i] == "other") {
            clean_discretized_vals[i] = "unknown"
        }
    }
    # removes duplicate 'unknown' if present (true for tob) but O(n)
    clean_discretized_vals = unique(clean_discretized_vals)
    return (clean_discretized_vals)
}

setColumnDefaultValue = function(indicator_string, lobi = 1) {
#   sets indicator column default value to 0. it's probably 
#   redundant to check the default value b/c it's provided 
#   in column creation syntax but can always turn it off if
#   too costly 

#   Parameters
#   ----------
#   indicator_string: a string e.g. 'electronic_medical_record', a discretized 
#       element of either lobi location_of_breached_information or tob 
#       type_of_breach

#   Returns: 
#   -------
#   NULL 

    check_default = "SELECT column_name, column_default 
                    FROM information_schema.columns 
                    WHERE (table_schema, table_name) = ('public', 'data_breach')
                    ORDER BY ordinal_position;"
    assigned_defaults = check_default %>% getData()
    prefix = "lobi_"
    if (!lobi) {
        prefix = "tob_"
    }
    column_name_str = paste(prefix, indicator_string, sep = "")
    cur_default_value = assigned_defaults %>% 
                            filter(column_name == column_name_str) %>% 
                            pull(column_default)
    if (cur_default_value == 0) {
        # return 0 if default value of indicator variable is 0 already 
        return (0)
    }
    query_string = "ALTER TABLE data_breach ALTER COLUMN " %>% 
                        paste(column_name_str) %>%
                        paste("SET DEFAULT 0;")
    conn = getPGDBConn()
    query = conn %>% DBI::dbSendQuery(query_string)
    query %>% DBI::dbClearResult()
    conn %>% DBI::dbDisconnect()
}

checkIndicatorExists = function(df, indicator_string, lobi = 1) {
#   whether an indicator column for tob type_of_breach or lobi 
#   location_of_breached_information exists and has default values set 

#   Parameters
#   ----------
#   lobi: a boolean for location_of_breached_information 
#       lobi = 0 ==> type_of_breach. it's included because both lobi and 
#       type_of_breach have 'unknown' as atomic values. thus, knowing whether 
#       the unknown is associated with type of breach or not helps ensure the
#       correct column name is used to detect if a variable exists  
#   df: a dataframe / tibble that's assigned all known data breaches 

#   Returns: 
#   -------
#   boolean
#       1 if column already exists and 0 if not based on the discreted 
#       element assigned to indicator_string and lobi boolean    

    prefix = "lobi"
    if (!lobi) {
        prefix = "tob"
    }
    col_indices = colnames(df) %>% 
                        lapply(str_detect, prefix) %>%
                        unlist()
    # colnames(df)[col_indices] returns only those columns that have 'lobi' 
    # or 'tob' prefixed. sum() after unlist() is not any other value 
    # than 0 or 1 with 1 indicating a column exists with the atomic value 
    # embedded in it 
    is_present = colnames(df)[col_indices] %>%
                    lapply(str_detect, indicator_string) %>% 
                    unlist() %>% 
                    sum() %>% 
                    as.logical()

    if (is_present) {
        # if column exists, ensures it has a default value of 0 set
        indicator_string %>% setColumnDefaultValue(lobi = lobi) 
    }
    return (is_present)
} 

createColumn = function(indicator_string, lobi = 1) {
#   creates a boolean (smallint) column in data_breach 
#   database table with name set to indicator_string 
#   and either lobi_ or tob_ prefixed 

#   Parameters
#   ----------
#   indicator_string: a string e.g. 'electronic_medical_record', a discretized 
#       element of either lobi location_of_breached_information or tob 
#       type_of_breach
#   lobi: a boolean for location_of_breached_information  
#       lobi = 0 ==> type_of_breach      
#   Returns 
#   -------
#   NULL 

    query_string_stem = "ALTER TABLE data_breach ADD COLUMN" 
    query_string = query_string_stem %>% paste("lobi_")
    if (!lobi) {
        query_string = query_string_stem %>% paste("tob_")
    }
    # the column is an indicator variable and has the constraints:
    # type: smallint (0 or 1)
    # default value of 0
    query_string = query_string %>% 
                        paste(indicator_string, sep = "") %>% 
                        paste("SMALLINT DEFAULT 0;")
    conn = getPGDBConn()
    query = conn %>% DBI::dbSendQuery(query_string)
    query %>% DBI::dbClearResult()
    conn %>% DBI::dbDisconnect()
}

setIndicator = function(indicator_string, lobi = 1) {
#   assigns the boolean column 'lobi_'indicator_string or 
#   'tob_'indicator_string = 1 on basis of value of type_of_breach 
#   if lobi = 0 or value of location_of_breached_information element 
#   of the row if lobi = 1

#   Parameters
#   ----------
#   indicator_string: a string e.g. 'electronic_medical_record', a discretized 
#       element of either lobi location_of_breached_information or tob 
#       type_of_breach
#   lobi: a boolean for location_of_breached_information  
#       lobi = 0 ==> type_of_breach      

#   Returns 
#   -------
#   NULL 

    # indicator_string is split on underscore b/c indicator_string 
    # e.g. 'electronic_medical_record' won't be matched otherwise.  
    # indicator_string_t is assigned first element. in the case of the 
    # above example c('electronic', 'medical', 'record') 'electronic'  
    # is fine for matching and indicator_strings w/o underscores will have 
    # length of 1 anyway. indicator_string_t is formatted as title e.g., 
    # 'Electronic' instead of 'electronic' due to HHS's encoding  
    indicator_string_t = indicator_string %>% 
                            str_split("_") %>% 
                            unlist()  
    indicator_string_t = indicator_string_t[1] %>% str_to_title()

    if (!lobi && str_detect(indicator_string, "other")) {
        indicator_string = "unknown"
        indicator_string_t = "Other"
    }
    prefix = "lobi_"
    # more like should be categorical col but that's too long 
    categorical_col = " location_of_breached_information "
    if (!lobi) {
        prefix = "tob_"
        categorical_col = " type_of_breach "
    }
    col_name = paste(prefix, indicator_string, sep = "")
    query_string_part1 = "UPDATE data_breach SET " %>% paste(col_name, " = 1 ")
    query_string_part2 = paste(" WHERE ",  categorical_col, " LIKE ")
    query_string_part3 = paste("'%", indicator_string_t, "%';", sep = "")
    query_string = query_string_part1 %>% paste(query_string_part2, query_string_part3)
    conn = getPGDBConn()
    query = conn %>% DBI::dbSendQuery(query_string)
    query %>% DBI::dbClearResult()
    conn %>% DBI::dbDisconnect()
}


ensureUknown = function(lobi = 1) {
#   encodes tob_unknown = 1 or lobi_unknown = 1 where type_of_breach 
#   holds 'Other' and likewise for location_of_breached_information. 
#   surest way to do these assignments is to hard-code them 

#   Parameters
#   ----------
#   lobi: a boolean for location_of_breached_information  
#       lobi = 0 ==> type_of_breach      
#   Returns 
#   -------
#   NULL 

    # ensureUknown() function is called in main() after createColumn() 
    # and setIndicator() are called: there's no risk that this setting of tob_unknown = 1 where 
    # type_of_breach holds 'Other' will attempt to assign values for a column 
    # that doesn't exist when explictly done via this function and same applies 
    # for location_of_breached_information with lobi_unknown
    col_name = " lobi_unknown "
    categorical_col = " location_of_breached_information "
    if (!lobi) {
        col_name = " tob_unknown "     
        categorical_col = " type_of_breach "
    }
    query_string = paste("UPDATE data_breach SET ", col_name, " = 1 WHERE ") %>% 
                    paste(categorical_col, " LIKE '%Other%'; ")
    conn = getPGDBConn()
    query = conn %>% DBI::dbSendQuery(query_string)
    query %>% DBI::dbClearResult()
    conn %>% DBI::dbDisconnect()
}

main = function(lobi = 1) {
#   creates lobi location_of_breached_information or tob 
#   type_of_breach indicator variables using the discretized 
#   values found in each column 

#   Parameters
#   ----------
#   lobi: a simple indicator with 0 being tob or 'type_of_breach' and 
#       default 1 indicating location_of_breached_information is the 
#       column whose elements are being discretized and assigned 

#   Returns 
#   -------
#   NULL 

    # retrieves all rows in data_breach table 
    data = "SELECT * FROM data_breach" %>% getData()

    # col_string is assigned column name as it exists in the database
    col_string = "location_of_breached_information" 
    if (!lobi) {
        col_string = "type_of_breach"
    }

    # discretized_vals is assigned the vector of discrete type_of_breach or 
    # location_of_breached_information elements with elements containing a 
    # slash '/' using the string preceding the slash and unknown absorbing 
    # any 'other' discrete values for lack of distinction 
    discretized_vals = discretize(
                            df = data,
                            col_string = col_string) %>% 
                            cleanDiscretizedValues()

    # created_col_inds is the vector holding boolean values: FALSE at indices 
    # where the corresponding index of discretized_vals has no column in the 
    # database indicating its presence in type_of_breach or 
    # location_of_breached_information 
    created_col_indices = discretized_vals %>% 
                            lapply(
                                checkIndicatorExists,
                                df = data,
                                lobi = lobi) %>% 
                            unlist()

    # creates columns in the data_breach table for all discretized_values 
    # in discretized_vals e.g., hacking for type_of_breach or network server 
    # for location_of_breached_information, at only indices that are assigned 
    # FALSE 
    discretized_vals[!created_col_indices] %>% 
    lapply(createColumn, lobi = lobi) %>% 
    unlist()

    # all discretized values in tob or lobi have columns assigned in the database 
    # indicating its presence in type_of_breach or location_of_breached_information 
    # for the distinct breach_id. each row of a given column is set to 0 by default 
    
    # setIndicator sets all rows to 1 where the discretized value e.g., 
    # improper_disposal for tob or electronic_medical_record for 
    # lobi, is present in type_of_breach or location_of_breached_information. 
    # this updates the rows where necessary and logically proceeds update of 
    # the database via upload_hhs_updates.R 
    discretized_vals %>% lapply(setIndicator, lobi = lobi)

    ensureUknown(lobi = lobi)
}

main()
main(0)

