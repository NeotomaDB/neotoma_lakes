library(rgdal)
library(neotoma)
library(dplyr)
library(purrr)
library(sp)
library(datasets)
library(rgeos)

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

  download.file(base_uri, temp)

  data <- unzip(temp, overwrite = TRUE)

  state_data <- readOGR(data[grep("waterbody.*shp$", data)])

  pol <- get_dataset(gpid = provs$prov[match(x, provs$abbr)],
                     datasettype = "pollen") %>% get_site

  class(pol) <- 'data.frame'

  coordinates(pol) <- ~ long + lat
  proj4string(pol) <- "+init=epsg:4326"

  areas <- over(spTransform(pol, proj4string(state_data)), state_data)

  areas$lake_area_ha <- sapply(areas$feature_id, function(x) {
    if(is.na(x)) {
      return(NA)
    } else {
      shape <- spTransform(state_data[state_data$feature_id %in% x,], "+init=epsg:3573")
      # Using a north pole lambert equal area. . .
      return(suppressWarnings(gArea(shape) / 10000))
    }
  })

  pol@data <- cbind(pol@data, areas)

  pol <- pol %>% as.data.frame(stringsAsFactors = FALSE)
  pol$nameMatch <- match(pol$site.name, state_data$name_en)

  if(any(!is.na(pol$nameMatch))) {
    pol$dist_match[!is.na(pol$nameMatch)] <- diag(spDists(as.matrix(pol[!is.na(pol$nameMatch),c('long', 'lat')]),
                              coordinates(state_data[na.omit(pol$nameMatch),]),
                              longlat = TRUE))
    pol$matched_lake[!is.na(pol$nameMatch)] <- state_data@data$feature_id[na.omit(pol$nameMatch)]

    areas$match_area <- sapply(areas$matched_lake, function(x) {
      if(is.na(x)) {
        return(NA)
      } else {
        shape <- spTransform(state_data[state_data$feature_id %in% x,], "+init=epsg:3573")
        # Using a north pole lambert equal area. . .
        return(suppressWarnings(gArea(shape) / 10000))
      }
    })
  }

  pol$state <- x

  return(pol)
}

states <- c("AB", "BC", "MB", "NB", "NL", "NS", "NT", "NU", "ON", "PE", "QC", "SK", "YT")

areas <- states %>%
  map(state_output) %>%
  bind_rows

areas_clean <- areas %>%
  select(site.id, site.name, long, lat, state, name_en, feature_id, lake_area_ha,
         nameMatch)

colnames(areas_clean)[1] <- "SiteID"

can_ds <- get_dataset(datasettype = 'pollen', gpid = 'Canada')

can_sites <- data.frame(DatasetID  = sapply(can_ds, function(x) x$dataset.meta$dataset.id),
                        SiteID = sapply(can_ds, function(x) x$site.data$site.id))

areas_output <- left_join(areas_clean, can_sites, by = 'SiteID')

readr::write_csv(areas_output, 'ca_lakes.csv')
