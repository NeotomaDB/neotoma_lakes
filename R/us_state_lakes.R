#' @title Extract lake information for Neotoma sites
#' @description Using the (US) state name, access Neotoma sites and find near matches within the US hydrology database.
#' @param x State name, abbreviated, as in \code{state.abb}.
#' @param laketable An optional dataframe, to test if sites have been accessed and modified previously.
#' @param datasettype The Neotoma Dataset type (default \code{"pollen"}).
#' @returns

us_state_lakes <- function(x,
                           laketable = NULL,
                           datasettype = "pollen") {

  state <- datasets::state.name[match(x, state.abb)]

  dset <- neotoma::get_dataset(gpid = state, datasettype = "pollen")

  if (!length(dset) > 0) {
    # Exit the function if there's no data for that state.
    return(data.frame(state = paste0(state, "NoData")))
  }

  pol <- dset %>% neotoma::get_site()

  class(pol) <- "data.frame"

  pol <- pol %>%
    mutate(dsid = sapply(dset,
                         function(x) {
                           x$dataset.meta$dataset.id
                         })) %>%
    dplyr::rename(`stid` = `site.id`)

  # Have lakes already been run?
  data_instate <- !is.na(match(pol$stid, laketable$stid))

  if (any(data_instate)) {

    matches <- match(pol$site.id, laketable$stid)

    pol$long <- lake_ds$long[matches]
    pol$lat  <- lake_ds$lat[matches]

  }

  # There are a couple states where we get an abnormally large return.

  if (length(dset) > 2774) {

    stop("There are too many sites in the state dataset.")

  } else {

    temp <- tempfile()

    state <- gsub(" ", "_", state)

    base_uri <- paste0("https://prd-tnm.s3.amazonaws.com/StagedProducts",
                       "/Hydrography/NHD/State/HighResolution/Shape/NHD_H_", state, "_State_Shape.zip")

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
        new_text <- st_as_text(state_data$geometry[x], EWKT = TRUE)

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

    get_output_pol <- cbind(pol, get_output)

    get_output_pol$state <- x
    get_output_pol$data_source <- base_uri

    nameMatch <- match(pol$site.name, state_data$GNIS_NAME)

    get_output_pol$match_area <- get_output_pol$dist_match <- NA

    if (any(!is.na(nameMatch))) {

      gdmatch <- !is.na(nameMatch)

      get_output_pol$dist_match[gdmatch] <- diag(st_distance(x = st_transform(pol_sf[gdmatch,],
                                                                                        crs = 2163),
                                                                       y = st_transform(state_data[na.omit(nameMatch),],
                                                                                        crs = 2163))) / 1000

      get_output_pol$match_area[gdmatch] <- state_data$AREASQKM[na.omit(nameMatch)]

    }

    return(get_output_pol)
  }
}
