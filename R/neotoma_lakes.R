#' @title Obtain all lakes from Neotoma
#' @description Uses a direct SQL call to find all lakes in Neotoma with existing site information.
#' @param x The connection string for the database.

neotoma_lakes <- function(x) {
  
  if(!file.exists(x)) {
    out <- data.frame(stid = NA,
                      dsid = NA,
                      sitename = NA,
                      long = NA,
                      lat = NA,
                      area = NA,
                      units = NA)
    return(out)
  }
  
  con_string <- jsonlite::fromJSON(x)
  
  con <- RPostgreSQL::dbConnect(RPostgreSQL::PostgreSQL(),
                   host = con_string$host,
                   port = con_string$port,
                   user = con_string$user,
                   password = con_string$password,
                   dbname = con_string$database)
  
  lake_query <- "SELECT
      lp.siteid AS stid, 
      ds.datasetid AS dsid,
      st.sitename,
      st.longitudeeast AS long, 
      st.latitudenorth AS lat,
      lp.value AS area,
      'ha'::text AS units,
      'Neotoma'::text AS source
    FROM
                  ndb.lakeparameters AS lp 
      INNER JOIN ndb.collectionunits AS cu ON           cu.siteid = lp.siteid 
      INNER JOIN        ndb.datasets AS ds ON ds.collectionunitid = cu.collectionunitid
      INNER JOIN           ndb.sites AS st ON           st.siteid = lp.siteid
    WHERE lp.lakeparameterid = 3 AND ds.datasettypeid = 3"
  
  lakes_area <- RPostgreSQL::dbGetQuery(con, lake_query)
  
  return(lakes_area)

}