library(lwgeom)
library(rgdal)
library(neotoma)
library(dplyr)
library(purrr)
library(sp)
library(datasets)
library(rgeos)
library(sf)

can_lakes <- readr::read_csv('ca_lakes.csv')

state_output <- function(x) {

  provs <- data.frame(abbr = c("AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT"),
                      prov = c("Alberta", "British Columbia", "Manitoba", "New Brunswick",
                               "Newfoundland and Labrador", "Nova Scotia", "Northwest Territories",
                               "Nunavut", "Ontario", "Prince Edward Island", "Quebec",
                               "Saskatchewan", "Yukon Territory"),
                      stringsAsFactors = FALSE)

  temp <- tempfile()

  base_uri <- paste0("ftp://ftp.geogratis.gc.ca/pub/nrcan_rncan/vector/canvec/shp/Hydro/canvec_250K_",
                     x, "_Hydro_shp.zip")

  download.file(base_uri, temp, quiet = TRUE, method = "wget")

  data <- unzip(temp, overwrite = TRUE)

  state_data <- st_read(data[grep("waterbody.*shp$", data)]) %>%
     st_transform(crs = 4326)

  gpid <- httr::GET("https://api.neotomadb.org/v2.0/data/geopoliticalunits",
                    query = list(gpname = provs$prov[match(x, provs$abbr)],
                                 rank = 2))

  gpcontent <- httr::content(gpid)$data$result[[1]]$geopoliticalid

  dset <- httr::GET("https://api.neotomadb.org/v2.0/data/sites",
                    query = list(gpid = gpcontent)) %>%
    httr::content() %>%
    pluck("data")

  for (i in length(dset):1) {
    tester <- dset[[i]]
    isPollen <- tester$collectionunits %>% map(function(y) {
      y$datasets %>% map(function(z) {
        z$datasettype
      })
    }) %>% unlist()
    dsid <- tester$collectionunits %>% map(function(y) {
      y$datasets %>% map(function(z) {
        z$datasetid
      })
    }) %>% unlist()

    if (!any(isPollen == "pollen")) {
      dset[[i]] <- NULL
    } else {
      dset[[i]]$datasetid <- dsid[which(isPollen == "pollen")]
    }
  }

  if (!length(dset) > 0) {
    # Exit the function if there's no data for that state.
    return(data.frame(state = paste0(state, "NoData")))
  }

  pol <- dset %>% map(function(x) {
    data.frame(siteid = x$siteid, sitename = x$sitename, geography = x$geography,
      datasetid = x$datasetid)
  }) %>% bind_rows()

  pol_sf <- geojsonsf::geojson_sf(pol$geography) %>% st_transform(crs = 4326)

  get_polydata <- function(x) {
    if (length(x) == 0) {
      return(data.frame(GNIS_ID = NA, feature_id = NA))
    } else {
      new_text <- st_as_text(state_data$geometry[x], EWKT = TRUE)

      output <- state_data[x, ] %>% as.data.frame %>% select(-geometry)

      output$geometry <- new_text
      return(output)
    }
  }

  get_output <- st_within(pol_sf, state_data) %>% map(get_polydata) %>% bind_rows()

  get_output$lake_area_m2 <- st_area(state_data)[match(get_output$feature_id,state_data$feature_id)]

  pol <- cbind(pol, get_output)

  pol$state <- x

  return(pol)
}

states <- c("AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT")

areas <- states %>%
  map(state_output) %>%
  bind_rows

areas_clean <- areas %>%
  select(siteid, sitename, geography, datasetid,
         state, name_en, feature_id, lake_area_ha)

readr::write_csv(areas_output, 'ca_lakes.csv')
