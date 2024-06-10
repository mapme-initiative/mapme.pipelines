source("src/000_setup.R")

bii_file <- "raw/lbii.asc"

if(!file.exists(bii_data)) {
  stop(sprintf("Biodiversity intactness index data needs to be downloaded manually and referenced in this script, so it can be found in '%s'. The dataset is available under this link: %s",
               bii_file,
               "https://data.nhm.ac.uk/dataset/global-map-of-the-biodiversity-intactness-index-from-newbold-et-al-2016-science"
       ))
}

fetch_bii <- function(x, fname_bii = bii_file, progress = TRUE) {
  with_progress({
    get_resources(x, get_biodiversity_intactness_index(fname_bii))
  }, enable = progress)
}

stats_bii <- function(
    x,
    progress = TRUE) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_biodiversity_intactness_index()
    )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = fetch_bii,
  calc_stats = stats_bii,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  out_path = out_path,
  suffix = "bii-indicators"
)

saveRDS(timings, file.path(out_path, "bii-timings.rds"))
