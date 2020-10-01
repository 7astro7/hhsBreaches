
# HHS Medical Breach Data

The Office for Civil Rights portal at [1] maintains an archive of data 
describing medical data breaches affecting 500 or more individuals 
stretching back to 2009. Above the data HHS says the following:
"As required by section 13402(e)(4) of the HITECH Act, the Secretary must post a 
list of breaches of unsecured protected health information affecting 500 or more 
individuals. The following breaches have been reported to the Secretary:"
There are more than 3,000 breaches described in the archive. 

A full analysis of the archived data isn't present in the public repo yet, although R code 
is in this initial commit that creates binary location of breached information and type of 
breach variables that might expedite efforts to model or process otherwise. As categorical 
variables these variables are practically meaningless and a glance at the data shows why. 
Among distinct values of the variable 'location of breached information' are 'Other', 
'Network Server, Other', and 'Network Server'. A module that automates PostgreSQL database 
connection and full insertion of the data is included that's viable as is given a PostgreSQL 
config file. 

All questions and feedback are welcomed. 

Data Sources:

[1]
US Dept. of Health and Human Services
Office for Civil Rights
https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf


