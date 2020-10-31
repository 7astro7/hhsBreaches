
library(DBI)

getPGDBConn = function(dbname = NULL, user = NULL, pw = NULL,
                    host = NULL, port = NULL) {
    # returns a connection object to PostgreSQL db
    # more explicit than version .01 of creating a connection 
    # in that it names environment variables as default 
    # connection params

    if (is.null(dbname)) {dbname = Sys.getenv("DBNAME")}
    if (is.null(user)) {user = Sys.getenv("PGUSER")}
    if (is.null(host)) {host = Sys.getenv("PGHOST")}
    if (is.null(port)) {port = Sys.getenv("PGPORT")}
    if (is.null(pw)) {pw = Sys.getenv("PGPW")}

    conn = DBI::dbConnect(
        RPostgres::Postgres(), 
        dbname = dbname,
        host = host, 
        port = port, 
        password = pw)
    return (conn)
}

