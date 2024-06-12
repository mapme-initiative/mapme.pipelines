remotes::install_github("mapme-initiative/mapme.biodiversity", upgrade = F)
remotes::install_github("mapme-initiative/mapme.indicators", ref = "dev", upgrade = F)

library(sf)
library(terra)
library(dplyr)
library(purrr)
library(future)
library(progress)
library(progressr)
library(landscapemetrics)
library(mapme.biodiversity)
library(mapme.indicators)
source("src/001_funs.R")

# should be set by you
ncores <- 18
options(timeout = 600)
wdpa_ver <- "Jun2024"
data_path <- "./data"
out_path <- "./output"
progress <- TRUE
by_region <- FALSE

# leave untouched from here on
handlers("progress")
mapme_options(outdir = data_path, retries = 5)
dir.create(data_path, showWarnings = FALSE)
dir.create(out_path, showWarnings = FALSE)

# fetch WDPA data
source("src/002_get_wdpa.R")
source("src/003_regions.R")
