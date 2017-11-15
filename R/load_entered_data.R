load_lakes <- function() {
  all_files <- list.files('data/by_hand/', full.names = TRUE)
  
  tests <- list()
  
  for(i in 1:length(all_files)) {
    if (stringr::str_detect(all_files[i], 'csv')) {
      tests[[i]] <- readr::read_csv(all_files[i])
    }
    if (stringr::str_detect(all_files[i], 'dbf')) {
      tests[[i]] <- foreign::read.dbf(all_files[i])
    }
  }
  
  return_core <- function(x) {
    if("SiteID" %in% colnames(x)) {
      colnames(x)[which(colnames(x) == "SiteID")] <- 'stid'
      colnames(x)[which(colnames(x) == "Edited")] <- 'edited'
      colnames(x)[which(colnames(x) == "Notes")] <- 'notes'
      colnames(x)[which(colnames(x) == "AREAHA")] <- 'area'
    }
    
    data.frame(stid = x$stid,
               edited = x$edited,
               notes = x$notes,
               area  = x$area,
               stringsAsFactors = TRUE)
  }
  
  all_tests <- tests %>% 
    purrr::map(return_core) %>% 
    dplyr::bind_rows() %>% 
    dplyr::group_by(stid, notes) %>% 
    dplyr::distinct()
  
  return(all_tests)
}