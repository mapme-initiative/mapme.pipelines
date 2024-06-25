library(sf)
library(terra)
library(dplyr)
library(purrr)
library(config)
library(future)
library(progress)
library(progressr)
library(landscapemetrics)
library(mapme.biodiversity)
library(mapme.indicators)
source("src/001_funs.R")

config <- config::get(config = "default")
# should be set by you
input <- config$input
ncores <- config$ncores
options(timeout = config$timeout)
data_path <- config$data_path
out_path <- config$output_path
progress <- config$progress
by_region <- config$by_region
overwrite <- config$overwrite

# leave untouched from here on
handlers("progress")
mapme_options(outdir = data_path, retries = 5)
dir.create(data_path, showWarnings = FALSE)
dir.create(out_path, showWarnings = FALSE)
