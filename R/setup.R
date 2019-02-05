library(purrr)
library(dplyr)
library(reshape2)
library(sf)
library(leaflet)
library(RPostgreSQL, quietly = TRUE, verbose = FALSE)

source('R/load_entered_data.R')
source('R/neotoma_lakes.R')
source('R/chron_output.R')
source('R/plot_lakes.R')
source('R/clean_matches.R')
source('R/plot_edited.R')

if (!paste0('version_', version) %in% list.files('data')) {
  dir.create(paste0('data/version_', version))
}
