# Revisiting Neotoma Lakes

A number of data records within Neotoma have been obtained from publications and legacy records from COHMAP and other sources.  Older records were often transformed from Degree-Minute-Second records to decimal degrees.  In this case there are two issues:

  * There is the appearance of greater accuracy/precision for the record's spatial location
  * The location of the sample site is not centered within the depositional basin from which the sample was obtained.

In particular, pollen based reconstruction methods (for climate or vegetation) often require knowledge of the size of the depositional basin.  For example, REVEALS (Sugita, 2007) requires knowledge of lake size when reconstructing vegetation.

Work underway for Northern Hemisphere reconstructions requires knowledge of lake sizes to be able to accurately estimate vegetation for the band from 40oN - 80oN, covering most of North America.  This repository contains code and summary output for a hybrid process that combines numerical analysis and GIS with itterative hand editing by individuals to align lacustrine and palustrine pollen datasets within North America with their depositional basins.

## Contributions

  * Simon Goring (code and repository management)
  * Bailey Zak
  * Claire Rubbelke - University of Wisconsin
  * Andria Dawson - Mount Royal University
  * Mathias Trachel - University of Wisconsin

## Project Components

### Rendered Document

The rendered document can be viewed as an HTML file from the Neotoma Open Computing pages:

  * [http://open.neotomadb.org/neotoma_lakes/check_lakes_report.html]()

The summary document, rendered as an Rmd to html using `rmarkdown::render()`, provides an overview of the code and its overall operation.  The hope is to develop a process that work interactively with both the Neotoma Paleoecology Database directly, and a web interface to provide the opportunity to dynamically examine and update lake locations.

Currently there are two part to the re-analysis:

  1.  Geographic co-location with existing hydological databases:  This code is run in two steps using files `R/GetLakeAreas_usa.R` and `R/GetLakeAreas_canada.R`.  This analysis requires downloading a large volume of data and is not recommended to be run on an individual user's computer.
  2.  Manual adjustment and measurement of lakes.  This work uses a GIS application such as ArcMap or QGIS to locate individual sites, adjust location if neccessary and subsequently measure the basin in which a site is located.

### Geographic Co-Location

For this work two files (`R/GetLakeAreas_usa.R` and `R/GetLakeAreas_canada.R`) are used.  These files run from the R directory and download ZIP files from servers for Canadian and US hydrological data.  These (often large) shapefiles are placed in temporary files using R's `tempfile()` function.  Intermediate data is saved to `data/runs.RDS` so that partial runs can be managed.  Output is saved as a file in `data/usa_lakes.csv` with a format:

| Parameter | Variable Type |
| --- | --- |
| site.id | int |
| DatasetID | int |
| site.name | char |
| long  | num  |
| lat | num  |
| state | char  |
| GNIS_NAME |  char |
| GNIS_ID | int |
|   AREASQKM | num |
| dist_match | num |
| data_source   |  char |

### Manual Adjustment

Manual adjustment involved working with `csv` and shapefiles in a workflow that evolved through time.  Intermediate results were saved in a folder called `data/by_hand`.  Within this folder there are a number of estimates for site locations and lake areas, in some cases these values overlap with two individuals having edited the same site.

Importing these files happens through the function `load_lakes()`, which is contained in the file `R/load_entered_data.R`.  This file recognizes either `csv` or `shp` files and processes them accordingly, returning a single output `data.frame` with the columns:

| Variable | Data Type |
| --- | --- |
| stid  | int |
| edited | int|
| notes | char |
| area | num |
| type | char |
| geometry | wkt (char)
| source | char |
| dsid | int |

These are combined with the aligned lakes from the earlier process, to create a composite dataset that is saved to file using a `version` number defined early in the `Rmd` file.  The output is then two files:

  * `area_lakes_....csv`: All lakes with defined areas.
  * `dataset_....shp`: Lakes that still require defined areas.
