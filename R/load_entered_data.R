load_lakes <- function() {
  all_files <- list.files('data/by_hand', 
                          full.names = TRUE, 
                          recursive = TRUE,
                          pattern = '(shp)|(csv)')
  
  tests <- list()
  
  for(i in 1:length(all_files)) {
    if (stringr::str_detect(all_files[i], 'csv')) {
      input_file <- readr::read_csv(all_files[i]) %>% 
        filter(!is.na(edited)) %>% 
        distinct(stid, edited, notes, area, X, Y, lat, long) %>% 
        as.data.frame()
      
      if (any(c('X', 'Y') %in% colnames(input_file))) {
        input_file <- st_as_sf(input_file, coords = c('X', 'Y'), crs = 4326)
      } else {
        input_file <- st_as_sf(input_file, coords = c('long', 'lat'), crs = 4326)
      }

    }
    if (stringr::str_detect(all_files[i], 'shp')) {
      input_file <- st_read(all_files[i]) 

      if("SiteID" %in% colnames(input_file)) {
        colnames(input_file)[which(colnames(input_file) == "SiteID")] <- 'stid'
        colnames(input_file)[which(colnames(input_file) == "Edited")] <- 'edited'
        colnames(input_file)[which(colnames(input_file) == "Notes")] <- 'notes'
        colnames(input_file)[which(colnames(input_file) == "AREAHA")] <- 'area'
      }
      
      input_file <- input_file %>% 
        filter(!is.na(edited)) %>% 
        select(stid, edited, notes, area)
    }
    
    input_file$area[input_file$area == 0] <- NA
    
    tests[[i]] <- input_file
  }

  all_tests <- do.call(rbind, tests) %>% 
    unique()
  
  return(all_tests)
}