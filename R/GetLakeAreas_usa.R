#  This script starts from scratch:

library(rgdal)
library(neotoma)
library(dplyr)
library(purrr)
library(sp)
library(datasets)
library(sf)

# lake_ds <- readr::read_csv("data/usa_lakes_wDS.csv")

state_output <- function(x) {

  state <- datasets::state.name[match(x, state.abb)]

  dset <- neotoma::get_dataset(gpid = state, datasettype = "pollen")

  if (!length(dset) > 0) {
    return(data.frame(state = paste0(state, "NoData")))
  }

  pol <- dset %>% neotoma::get_site()

  class(pol) <- "data.frame"
  pol$DatasetID <- sapply(dset, function(x)x$dataset.meta$dataset.id)

  if (any(!is.na(match(pol$site.id, lake_ds$SiteID)))) {

    matches <- match(pol$site.id, lake_ds$SiteID)

    pol$long <- lake_ds$long[matches]
    pol$lat  <- lake_ds$lat[matches]

  }

  if (length(dset) < 2774 & length(dset) > 0) {
    temp <- tempfile()

    state <- gsub(" ", "_", state)

    base_uri <- paste0("http://prd-tnm.s3-website-us-west-2.amazonaws.com/StagedProducts",
                       "/Hydrography/NHD/State/HighResolution/Shape/NHD_H_", state, "_Shape.zip")

    test_dl <- try(download.file(base_uri, temp))

    if ("try-error" %in% class(test_dl)) {
      return(cbind(data.frame(GNIS_ID = NA, pol)))
    }

    data <- unzip(temp, overwrite = TRUE)

    pol_sf <- st_as_sf(pol,
                       coords = c("long", "lat"),
                       crs = 4326)

    state_data <- st_read(data[grep("NHDWaterbody.shp", data)]) %>%
      st_transform(crs = 4326)

    get_polydata <- function(x) {
      if (length(x) == 0) {
        return(data.frame(GNIS_ID = NA))
      } else {
        new_text <- st_as_text(state_data$geometry[x], EWKT=TRUE)

        output <- state_data[x,] %>%
          as.data.frame %>%
          select(-geometry)

        output$geometry <- new_text
        return(output)
      }
    }

    get_output <- st_within(pol_sf, state_data) %>%
      map(get_polydata) %>%
      bind_rows

    get_output_pol <- cbind(get_output, pol)

    get_output_pol$state <- x
    get_output_pol$data_source <- base_uri

    nameMatch <- match(pol$site.name, state_data$GNIS_NAME)

    if (any(!is.na(nameMatch))) {

      get_output_pol$match_area <- get_output_pol$dist_match <- NA

      gdmatch <- !is.na(nameMatch)

      get_output_pol$dist_match[gdmatch] <- diag(st_distance(x = st_transform(pol_sf[gdmatch,],
                                                                                        crs = 2163),
                                                                       y = st_transform(state_data[na.omit(nameMatch),],
                                                                                        crs = 2163))) / 1000

      get_output_pol$match_area[gdmatch] <- state_data$AREASQKM[na.omit(nameMatch)]

    }

    return(get_output_pol)
  } else {
    return (data.frame(GNIS_ID = NA))
  }
}

states <- state.abb

runs <- readRDS("data/runs.RDS")

for (i in 1:length(states)) {
  runs[[i]] <- try(state_output(states[i]))
  saveRDS(runs, paste0("data/runs.rds"))

  # Clean temprary files:
  file.remove(list.files(tempdir(), full.names = TRUE, recursive = TRUE))
  file.remove(list.files("Shape", full.names = TRUE, recursive = TRUE))
  gc()
}

for (i in length(runs):1) {
  if ("try-error" %in% class(runs)) {
    runs[[i]] <- NULL
  }
}

areas <- bind_rows(runs)

areas_clean <- areas %>%
  dplyr::select(site.id, DatasetID, site.name, long, lat, state, GNIS_NAME, GNIS_ID, AREASQKM,
         dist_match, data_source)

colnames(areas_clean)[1] <- "SiteID"
areas_clean$AREAHA <- areas_clean$AREASQKM * 100

readr::write_csv(areas_clean, "data/usa_lakes.csv")

read_geom <- function(x) {

  matches <- data.frame(start =      regexpr("[0-9]{4};", x),
                        end   = attr(regexpr("[0-9]{4};", x), "match.length"))

  with(matches,
       st_as_sfc(substr(x, start + end, nchar(x)), crs = as.numeric(substr(x, start, start + end - 2))))
}
