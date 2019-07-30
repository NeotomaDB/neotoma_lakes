load_lakes <- function() {
  all_files <- list.files('data/by_hand',
                          full.names = TRUE,
                          recursive = TRUE,
                          pattern = '(shp)|(csv)')

  tests <- list()

  for(i in 1:length(all_files)) {
    if (stringr::str_detect(all_files[i], 'csv')) {

      input_file <- readr::read_csv(all_files[i]) %>%
        filter(!is.na(edited))

      if (any(c('X', 'Y') %in% colnames(input_file))) {

        input_file <- input_file %>%
          distinct(stid, dsid, edited, notes, area, X, Y, type) %>%
          as.data.frame() %>%
          st_as_sf(coords = c('X', 'Y'), crs = 4326)

      } else {

        input_file <- input_file %>%
          distinct(stid, dsid, edited, notes, area, lat, long, type) %>%
          as.data.frame() %>%
          st_as_sf(coords = c('long', 'lat'), crs = 4326)

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
      if("DepType" %in% colnames(input_file)) {
        colnames(input_file)[which(colnames(input_file) == "DepType")] <- 'type'
      }

      input_file <- input_file %>%
        filter(!is.na(edited)) %>%
        select(stid, edited, notes, area, contains("type", ignore.case = FALSE))
    }

    input_file$area[input_file$area == 0] <- NA
    input_file <- input_file
    input_file$source <- rep(all_files[i], nrow(input_file))

    tests[[i]] <- input_file
  }

  all_tests <- tests %>%
    plyr::ldply() %>%
    arrange(type) %>%
    distinct(stid, dsid, edited, notes, area, source, .keep_all = TRUE)

  return(all_tests)
}
