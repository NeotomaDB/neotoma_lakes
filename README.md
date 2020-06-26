# Revisitng Neotoma Lakes

A number of data records within the Neotoma Paleoecology Database ([http://neotomadb.org](http://neotomadb.org)) have been obtained from publications and legacy records from COHMAP, the North American Pollen Database, and other sources.  Older records were often transformed from degree-minute-second records (e.g., 49°20'00") to decimal degrees (40.33333°).  In this case there are two issues:

  * There is the appearance of greater accuracy/precision for the record's spatial location (the record is reported to *n* decimal places)
  * The location of the sample site is not centered within the depositional basin from which the sample was obtained.

Pollen based reconstruction methods (for climate or vegetation) often require knowledge of the size of the depositional basin.  For example, REVEALS ([Sugita, 2007](https://doi.org/10.1177/0959683607075837)) requires knowledge of lake size when reconstructing vegetation from pollen records.

Work underway for Northern Hemisphere reconstructions requires knowledge of lake sizes to be able to accurately estimate vegetation for the band from 40°N - 80°N, covering most of North America.  The `neotoma_lakes` repository contains code and summary output for a hybrid process that combines numerical analysis and GIS with itterative hand-editing by individuals to align lacustrine and palustrine pollen datasets within North America with their depositional basins.

## Contributions

  * [Simon Goring](http://goring.org) (code and repository management)
  * Bailey Zak
  * Claire Rubbelke - University of Wisconsin
  * Andria Dawson - Mount Royal University
  * Mathias Trachel - University of Wisconsin

## Project Components

### Rendered Summary Document

The rendered document can be viewed as an HTML file from the [Neotoma Open Computing](http://open.neotomadb.org) pages:

  * [check_lakes_report.html](http://open.neotomadb.org/neotoma_lakes/check_lakes_report.html)

The summary document, rendered from an Rmd to html using `rmarkdown::render()`, provides an overview of the code and its overall operation.  The hope is to develop a process that work interactively with both the Neotoma Paleoecology Database directly, and a web interface to provide the opportunity to dynamically examine and update lake locations.

The interactive report can be generated from the commandline using:

```bash
make runreport
```

### Geographic Co-Location

For this work two files (`R/GetLakeAreas_usa.R` and `R/GetLakeAreas_canada.R`) are used.  These files run from the R directory and download ZIP files from servers for Canadian and US hydrological data.  These (often large) shapefiles are placed in temporary files using R's `tempfile()` function.  Intermediate data is saved to `data/runs.RDS` so that partial runs can be managed.  Output is saved as a file in `data/usa_lakes.csv` with a format:

| Parameter   | Variable Type |
|-------------|---------------|
| site.id     | int           |
| DatasetID   | int           |
| site.name   | char          |
| long        | num           |
| lat         | num           |
| state       | char          |
| GNIS_NAME   | char          |
| GNIS_ID     | int           |
| AREASQKM    | num           |
| dist_match  | num           |
| data_source | char          |

Both the Canadian and USA data can be run using the bash command:

```bash
make runlakes
```

This will sequentially download USA and Canadian lake shapefiles, and then begin to match lake sites in Neotoma to the actual lake polygons in the hydrographic databases.

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

## References

Sugita (2007) Theory of quantitative reconstruction of vegetation I: pollen from large sites REVEALS regional vegetation composition. Holocene 17:229–241
