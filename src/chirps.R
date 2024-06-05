source("src/000_setup.R")

fetch_chirps <- function(x, progress) {
  with_progress({
    get_resources(
      x,
      get_chirps(1981:2022)
    )
  }, enable = progress)
}


stats_chirps <- function(x, progress) {
  with_progress({
      inds <- calc_indicators(
        x,
        calc_precipitation_chirps(years = 1981:2022, engine = "exactextract")
      )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = fetch_chirps,
  calc_stats = stats_chirps,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 5000000,
  out_path = out_path,
  suffix = "chirps-indicators"
)

saveRDS(timings, file.path(out_path, "chirps-timings.rds"))
