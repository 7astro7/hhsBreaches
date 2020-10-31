
# This module is responsible for uploading the full store of data from hhs as 
# of 21 September 2020
# Other modules are responsible for updating the database

# remove archive variable 
# question to answer: 
#   what will the sequence be? 
#   will there be a separate table for type of breach and location of breached information?

library(dplyr)
source("ogCleaning.R")
source("dbc.R")

# sources original data from ogCleaning.R module
# additions to data are incremental after this initial 
# upload (cron job) 
# method from ogCleaning.R returning tidy data
data = getOgData()

# method from dbc.R returning connection object
conn = getPGDBConn()

# no foreign key specified because only one table is needed 
# at current stage of analysis
query = conn %>% DBI::dbSendQuery( 
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
    archive SMALLINT DEFAULT 0
    );") 
    
query %>% 
DBI::dbClearResult() 

# appends rows to table, closes connection
DBI::dbWriteTable(conn, "data_breach", data, append = TRUE)

conn %>% 
DBI::dbDisconnect()

