#' @title Extract lake information for Neotoma sites
#' @description Using the (US) state name, access Neotoma sites and find near matches within the US hydrology database.
#' @param x State name, abbreviated, as in \code{state.abb}.
#' @param laketable An optional dataframe, to test if sites have been accessed and modified previously.
#' @param datasettype The Neotoma Dataset type (default \code{'pollen'}).
#' @returns

us_state_lakes <- function(x, laketable = NULL, datasettype = "pollen") {

  state <- datasets::state.name[match(x, state.abb)]

  gpid <- httr::GET("https://api.neotomadb.org/v2.0/data/geopoliticalunits", query = list(gpname = state,
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

  # # Have lakes already been run?  data_instate <- !is.na(match(pol$siteid,
  # laketable$stid)) if (any(data_instate)) { matches <- match(pol$siteid,
  # laketable$stid) pol$long <- lake_ds$long[matches] pol$lat <-
  # lake_ds$lat[matches] }

  # There are a couple states where we get an abnormally large return.

  temp <- tempfile()

  state <- gsub(" ", "_", state)

  base_uri <- paste0("https://prd-tnm.s3.amazonaws.com/StagedProducts", "/Hydrography/NHD/State/HighResolution/Shape/NHD_H_",
    state, "_State_Shape.zip")

  test_dl <- try(download.file(base_uri, temp, quiet = TRUE, method = "wget"))

  if ("try-error" %in% class(test_dl)) {
    return(cbind(data.frame(GNIS_ID = NA, pol)))
  }

  data <- try(unzip(temp, overwrite = TRUE))

  if ("try-error" %in% class(data)) {
    return(cbind(data.frame(gnis_id = NA, state = x, pol)))
  }

  # CRS:4326 is standard lat/long
  pol_sf <- geojsonsf::geojson_sf(pol$geography) %>% st_transform(crs = 4326)

  state_data <- st_read(data[grep("NHDWaterbody.shp$", data)]) %>% st_transform(crs = 4326)

  get_polydata <- function(x) {
    if (length(x) == 0) {
      return(data.frame(GNIS_ID = NA))
    } else {
      new_text <- st_as_text(state_data$geometry[x], EWKT = TRUE)

      output <- state_data[x, ] %>% as.data.frame %>% select(-geometry)

      output$geometry <- new_text
      return(output)
    }
  }

  get_output <- st_within(pol_sf, state_data) %>% map(get_polydata) %>% bind_rows()

  get_output_pol <- cbind(pol, get_output)

  get_output_pol$state <- x
  get_output_pol$data_source <- base_uri

  nameMatch <- match(pol$site.name, state_data$GNIS_NAME)

  get_output_pol$match_area <- get_output_pol$dist_match <- NA

  if (any(!is.na(nameMatch))) {

    gdmatch <- !is.na(nameMatch)

    get_output_pol$dist_match[gdmatch] <- diag(st_distance(x = st_transform(pol_sf[gdmatch,
      ], crs = 2163), y = st_transform(state_data[na.omit(nameMatch), ], crs = 2163)))/1000

    get_output_pol$match_area[gdmatch] <- state_data$AREASQKM[na.omit(nameMatch)]

  }

  return(get_output_pol)
}
