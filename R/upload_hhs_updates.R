
# This module scrapes the HHS portal and identifies discrepencies between 
# the data within postgres DB for the project and data for cases currently 
# under investigation: it updates the postgres DB with new data from HHS
# Can be run as a cron job 
library(DBI);
library(rvest)
library(dplyr)
library(stringr)
source("dbc.R")

# the url used to retrieve HTML from hhs site 
# request generates records pertaining to the last 24 months 
# that are currently under investigation of Office for Civil Rights
hhs_url <-  "https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf#"

getAllTableNodes <- function(url) {
        # takes a url as input and returns all html table nodes 
        # from the html file returned from read_html()
        both_html_tables <- url %>% 
                                read_html() %>% 
                                html_nodes("table")
        return (both_html_tables)
}

getUpdateTbl <- function(table_nodes) {
        # takes html table nodes as input 

        # the second element of table_nodes stores the node corresponding to 
        # the table that contains hhs updates. html_table() produces a 
        # dataframe of most recent hhs data embedded in a list object
        tbl_with_updates <- table_nodes[2] %>% html_table()

        # all data stored in the first element of the list is stored in 
        # a data frame and it's assigned to tibble2 except for the first 
        # column which is nondescript and holds NAs
        updates <- tbl_with_updates[[1]][-1] %>% as_tibble() 
        return (updates)
}

getIdentifyingColumns <- function(df) {
        # takes a dataframe as input and returns a subset of this 
        # dataframe. the elements of the subset are two columns>>
        # two uniquely identifying columns: 
        # breach submission date, and name of covered entity are 
        # extracted and returned 
        id_tibble <- df %>%
                        select('Breach Submission Date', 'Name of Covered Entity') %>%
                        rename(breach_submission_date = 'Breach Submission Date', 
                        name_of_covered_entity = "Name of Covered Entity") %>%
                        mutate(breach_submission_date = 
                        as.Date(breach_submission_date, "%m/%d/%Y"))
        return (id_tibble)
}

getAllNonArchiveData <- function() {

        # queries all records from data_breach DB table stored in columns
        # breach submission date and name of covered entity so that any 
        # updates on hhs site that aren't in the project's DB can be identified 
        # Note: as mentioned in comment at top of module, the hhs site shows 
        # only data from last 24 months by default b/c the default page has data 
        # on medical data breach cases from the last 24 months that are currently
        # under investigation by the Office for Civil Rights 
        
        query <- getPGDBConn() %>% DBI::dbSendQuery(
                "SELECT breach_submission_date, name_of_covered_entity
                FROM data_breach WHERE CURRENT_DATE - breach_submission_Date <= (365 * 2)
                ORDER BY breach_submission_date DESC;")
        # retrieves records specified by query above 
        dates_in_db <- query %>% DBI::dbFetch()
        query %>% DBI::dbClearResult() 
        return (dates_in_db)
}

checkNewDataExists <- function(html_data_hhs_portal) {
        # takes as input: a tibble that stores data currently posted 
        # on the HHS portal. the data describes medical data breaches 
        # that are not yet in the HHS archive: the data describes 
        # medical data breaches that are currently under investigation

        # returns: rows that are published on hhs site but that aren't  
        # stored in project DB


        # id_tibble is a two-column subset of the data for breaches 
        # that are currently under investigation and stored at the 
        # main page of the HHS portal (not in the archive tab).
        # the two columns in the subset are breach_submission_date and 
        # name_of_covered_entity. it's assumed that these variables 
        # uniquely identify rows and this operation is necessary because 
        # these data have not had breach_id assigned yet 
        id_tibble <- html_data_hhs_portal  %>% getIdentifyingColumns()

        # dates_in_db is a tibble with the same columns as id_tibble:
        # it stores all rows in these two columns that have 
        # breach_submission_date only as old as 24 months but not 
        # older
        dates_in_db <- getAllNonArchiveData()

        # the set asymmetric difference is calculated:
        # setdiff(id_tibble, dates_in_db) returns all 
        # data for breaches that are currenty under investigation
        # that are not also in the PostgreSQL database 
        difference_tibble <- setdiff(id_tibble, dates_in_db)
        
        return (difference_tibble)
}

getLastAssignedBreachID <- function(a_connection) {
        # takes a DBI connection object as input 
        # returns column names as they are assigned in DB along with the most 
        # recent breach_id that's been assigned to data in the project's DB 
        query <- a_connection %>% DBI::dbSendQuery(
                "SELECT * FROM data_breach
                WHERE breach_id = (SELECT MAX(breach_id) 
                        FROM data_breach);")
        names_and_ids <- query %>% 
                                DBI::dbFetch() %>% 
                                as_tibble()
        query %>% DBI::dbClearResult()
        return (names_and_ids)
}

putNewData <- function(hhs_url) {
        # goal of this function: 
        # if there's new data on HHS site-data on the HHS portal  
        # that's not yet in the PostgreSQL database- then put the 
        # new data in the database 
        
        # input: a url for the HHS main site 
        
        # returns: 
        # a string saying "PostgreSQL DB is up to date" if 
        # no rows exist on HHS main page that aren't in the 
        # project's database OR
        # a string informing the caller how many rows have 
        # been inserted to the PostgreSQL database from the 
        # update
        
        # new_data_from_hhs is assigned all html nodes that 
        # hold 'table' objects 
        new_data_from_hhs <- hhs_url %>% getAllTableNodes()

        # scraped_data_tibble is assigned the structured, tibble 
        # form of the table that's stored at node #2 of 
        # new_data_from_hhs. if this is ambiguous it's an 
        # rvest method that's making the tibble from the html
        scraped_data_tibble <- new_data_from_hhs %>% 
                                        getUpdateTbl() 

        ### makes "Business Associate Present" column explicitly
        ### an indicator variable storing integers

        # holds logical values that are true if index holds "Yes"
        biz_associate_col_as_lgl <- scraped_data_tibble[["Business Associate Present"]] == "Yes" 

        # changes all FALSE to 0 and TRUE to 1, not only FALSE to 0 
        biz_associate_col_as_lgl[biz_associate_col_as_lgl == FALSE] <- 0 

        # business associate present column is stored as indicator variable 
        scraped_data_tibble[["Business Associate Present"]] <- biz_associate_col_as_lgl

        # difference_tibble holds all rows for medical data breaches that are from 
        # the past 24 months that are Cases Currently Under Investigation 
        # but that aren't yet in the PostgreSQL DB
        difference_tibble <- scraped_data_tibble %>% checkNewDataExists()

        # no_new_data is assigned TRUE if no data is on the HHS portal that's 
        # not already in the PostgreSQL database 
        no_new_data <- nrow(difference_tibble) == 0
        
        if (no_new_data) {
                return ("PostgreSQL database is up to date")
        }

        # column names of columns in DB and the last breach_id that's been 
        # assigned are stored  
        colnames_and_last_id <- getPGDBConn() %>% getLastAssignedBreachID()

        # the column names as they exist in the project's DB are assigned 
        # to proper_column_names 
        proper_column_names <- colnames(colnames_and_last_id)

        # the column name at first index of proper column names is dropped
        # because a join operation that will output not just name of covered entity and 
        # breach submission date but also all other columns of the new rows to upload to the 
        # project's DB. this operation won't work if breach_id column is present in columns from 
        # project's DB but not in the new rows to add to the DB that were retrieved from 
        # the HHS url 
        proper_column_names_for_join <- proper_column_names[-1]

        # the column names as they exist in project's DB replace the similair but 
        # uppercase column names of the new data in scraped_data_tibble
        colnames(scraped_data_tibble) <- proper_column_names_for_join

        # breach_submission_date in tibble_updates now holds a date type stored in 
        # mdy format: month-day-year 
        scraped_data_tibble <- scraped_data_tibble %>% 
                                mutate(breach_submission_date = 
                                as.Date(breach_submission_date, "%m/%d/%Y"))

        # difference_tibble which holds the rows that need to be added to the 
        # project's DB is left joined to tibble_updates so that not only 
        # name_of_covered entity and breach_submission_date but also all other columns 
        # pertaining to the new data are available to be uploaded to project's DB  
        data_to_update_db_with <- left_join(difference_tibble, scraped_data_tibble, 
                by = c("name_of_covered_entity", "breach_submission_date"))

        # adds archive indicator column, set to zero by default 
        data_to_update_db_with <- data_to_update_db_with %>% mutate(archive = 0)

        # update the project's DB
        conn <- getPGDBConn() 
        conn %>% DBI::dbWriteTable("data_breach", data_to_update_db_with, append = TRUE)
        conn %>% DBI::dbDisconnect()
        insertion_info <- paste(nrow(difference_tibble), " new row(s) inserted to DB")
        print(insertion_info)
        return (insertion_info)
}

g <- putNewData(hhs_url)
g
