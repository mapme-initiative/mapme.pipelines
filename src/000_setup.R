remotes::install_github("mapme-initiative/mapme.biodiversity", ref = "dev")
library(sf)
library(terra)
library(future)
library(progressr)
library(mapme.biodiversity)
library(mapme.indicators)
source("src/000_funs.R")

# should be set by you
ncores <- 18
options(timeout = 600)
data_path <- "./data"
out_path <- "./output"

# leave untouched from here on
handlers("progress")

dir.create(data_path, showWarnings = FALSE)
dir.create(out_path, showWarnings = FALSE)

mapme_options(outdir = data_path, chunk_size = 150000, retries = 5)

aoi <- read_sf(
  file.path(data_path, "wdpa_worldwide.gpkg"),
  query = "select * from 'wdpa_worldwide' where ISO3 = 'MEX';")

aoi <- order_parallel(aoi, ncores = ncores)
