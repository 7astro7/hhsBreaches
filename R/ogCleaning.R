
# Data source: 
#"https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf"
# According to HHS, for data categorized as 
# "Cases Currently Under Investigation": 
# """This page lists all breaches reported within the last 24 months 
# that are currently under investigation by the Office for 
# Civil Rights."""  
# For "Archive" category:  
# """This page archives all resolved breach reports and/or reports 
# older than 24 months. """
# >Research Report< 
#   option that combines archive and under investigation 
#           -not used because it's somewhat more ambigous 

# This module prepares data from original CSVs for uploading to
#  postgres DB 

# under inv: https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf
# https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf

# archive: https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf

# archive data and currently under investigation data are at the same
# url
# >>> no url points to csvs

library(dplyr); 
library(readr)
library(stringr)

whitespaceToUnderscore <- function(df) {
    # replaces whitespace characters in column 
    # names of given tibble with underscores

    for (i in 1:ncol(df)) {
        # condition is included only for redundancy 
        while (str_detect(colnames(df)[i], " ")) {
            colnames(df)[i] <- str_replace(colnames(df)[i], " ", "_")
        }
    }
    return (df)
}

categorizeFactors <- function(df) {
    # changes type of columns: State, Location 
    # of Breached Information, Covered Entity Type, Type of 
    # Breach, Business Associate Present (will be made binary 
    # later in module), Name of Covered Entity to categorical  

    new_df <- df %>%
        mutate(State = factor(State), 
        Location_of_Breached_Information = 
            factor(Location_of_Breached_Information), 
        Covered_Entity_Type = factor(Covered_Entity_Type), 
        Type_of_Breach = factor(Type_of_Breach), 
        Business_Associate_Present = factor(Business_Associate_Present), 
        Name_of_Covered_Entity = factor(Name_of_Covered_Entity))
    return (new_df)
}

assignBreachSubmissionDate <- function(df) {
    # changes type of Breach Submission Date column 
    # from character to Date. uses lubridate package's 
    # mdy specification  

    df_with_correct_dates <- df %>%
                mutate(Breach_Submission_Date = 
                    lubridate::mdy(Breach_Submission_Date))
    return (df_with_correct_dates)
}

toLowerCase <- function(df) {
    # changes column names to lower case versions
    # of current names

    new_df <- df %>%
            rename(name_of_covered_entity = Name_of_Covered_Entity, 
            state = State, covered_entity_type = Covered_Entity_Type, 
            individuals_affected = Individuals_Affected, 
            breach_submission_date = Breach_Submission_Date, 
            type_of_breach = Type_of_Breach, 
            location_of_breached_information = 
                Location_of_Breached_Information, 
            business_associate_present = Business_Associate_Present, 
            web_description = Web_Description)
    return (new_df)
}

dichotomizeBAP <- function(df) {
    # makes the type of business_associate_present 
    # column binary / integer, from categorical 

    # creates the binary variable to be encoded correctly / 
    # coded as integer that will replace current variable w/ 
    # categorical encoding 
    new_df <- df %>% 
        mutate(biz_a_present = 0)
    
    # groups rows according to value of business_associate_present 
    # column. stores the number of rows in this summary table. 
    # if it's greater than 2 encoding as integer binary isn't 
    # doable without delay
    number_of_groups <- new_df %>% 
                distinct(business_associate_present) %>% 
                nrow()
    twoGroups <- number_of_groups == 2
    if (!twoGroups) {
        stop("Business associate present has more than two groups, 
        returning exit code 1")
        return (1)
    }

    # creates a subset of rows where business associate
    # present == 1. rows of stand-in, temporary variable 
    # biz_a_present are assigned value of 1  
    present_subset <- new_df %>% 
        filter(business_associate_present == "Yes") %>% 
        mutate(biz_a_present = 1)
    # creates subset complimentary to subset just created ^^
    not_present_subset <- new_df %>% 
        filter(business_associate_present != "Yes")
    
    # rows of correctly-coded subsets are bound
    new_df <- bind_rows(present_subset, not_present_subset)
    
    # business associate present variable with old 
    # encoding is dropped 
    new_df <- new_df %>% 
        mutate(business_associate_present = NULL)

    new_df <- new_df %>% 
        rename(business_associate_present = biz_a_present)
    return (new_df)
}

arch <- read_csv("data/archive.csv")
under <- read_csv("data/under_investigation.csv")
#nrow(arch)
#nrow(under)

arch <- arch %>% 
    whitespaceToUnderscore() %>% 
    categorizeFactors() %>% 
    assignBreachSubmissionDate() %>% 
    toLowerCase() %>% 
    dichotomizeBAP()
under <- under %>% 
    whitespaceToUnderscore() %>% 
    categorizeFactors() %>% 
    assignBreachSubmissionDate() %>% 
    toLowerCase() %>% 
    dichotomizeBAP()

bindRowsIfDisjoint <- function(archiveDF, currentDF) {
    # binds the rows of the two tibbles if intersection of 
    # tibbles <- {}. a dichotomous archive variable is created for
    # identification 

    # the sets have identical column names, 
    # use of extra param 'by' foregone 
    # empty_set is assigned true if there's no evidence of 
    # common rows in archive data and current data 
    joined_sets <- left_join(currentDF, archiveDF)
    empty_set <- nrow(joined_sets) == nrow(currentDF)

    # if the opp. of empty_set is true then except
    if (!empty_set) {
        stop("Rows of the data sets aren't mutually exclusive. 
        Returning exit code 1")
        return (1)
    }
    new_archive <- archiveDF %>% 
            mutate(archive = 1)
    new_current <- currentDF %>% 
            mutate(archive = 0)
    return (bind_rows(new_archive, new_current))
}

data_all <- bindRowsIfDisjoint(currentDF = under, archiveDF = arch)

getOgData <- function() {
    return (data_all)
}

