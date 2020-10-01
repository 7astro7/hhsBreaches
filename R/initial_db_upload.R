
# This module is responsible for uploading the full store of data from hhs as 
# of 21 September 2020
# Other modules are responsible for updating the database

library(dplyr)
source("ogCleaning.R")

# sources original data from ogCleaning.R module
# additions to data are incremental after this initial upload
data <- getOgData()

# no arguments b/c config file sets connetion params
conn <- DBI::dbConnect(RPostgres::Postgres())

# no foreign key specified because only one table is needed 
# at current stage of analysis
query <- conn %>% DBI::dbSendQuery( 
    "CREATE TABLE IF NOT EXISTS data_breach (
    breach_id SERIAL PRIMARY KEY, 
    name_of_covered_entity VARCHAR, 
    state VARCHAR, 
    covered_entity_type VARCHAR, 
    individuals_affected NUMERIC, 
    breach_submission_date DATE, 
    type_of_breach VARCHAR, 
    location_of_breached_information VARCHAR, 
    web_description VARCHAR, 
    business_associate_present SMALLINT, 
    archive SMALLINT
    );") %>% 
    DBI::dbClearResult() 

# appends rows to table, closes connection
DBI::dbWriteTable(conn, "data_breach", data, append = TRUE)

conn %>% 
DBI::dbDisconnect()

