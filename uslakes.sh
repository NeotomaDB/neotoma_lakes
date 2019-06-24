#!/bin/bash -e

nohup Rscript -e "rmarkdown::render('usa_lakes.Rmd')" > lakerender.out 2>&1 &
