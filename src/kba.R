source("src/000_setup.R")

kba_file <- "raw/kba.gpkg"

if(!file.exists(kba_data)) {
  stop(sprintf("Key Biodiversity Area data needs to be downloaded manually and referenced in this script, so it can be found in '%s'. The dataset is available under this link: %s",
               kba_file,
               "https://www.keybiodiversityareas.org/kba-data"
       ))
}

fetch_kba <- function(x, progress = TRUE) {
  fname_kba <- "raw/kba.gpkg"
  with_progress({
    get_resources(x, get_key_biodiversity_areas(fname_kba))
  }, enable = progress)
}

stats_kba <- function(
    x,
    progress = TRUE) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_key_biodiversity_area()
    )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = fetch_kba,
  calc_stats = stats_kba,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  out_path = out_path,
  suffix = "kba-indicators"
)

saveRDS(timings, file.path(out_path, "kba-timings.rds"))
