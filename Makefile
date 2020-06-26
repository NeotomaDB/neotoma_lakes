runlakes: R/GetLakeAreas_usa.R R/GetLakeAreas_can.R
	echo Running data access for Canada and the USA.
	echo This uses a large volume of internet traffic, so please be aware.
	Rscript R/GetLakeAreas_usa.R
	Rscript R/GetLakeAreas_can.R

runreport: check_lakes_report.Rmd
	Rscript -e "rmarkdown::render(check_lakes_report.R)"
