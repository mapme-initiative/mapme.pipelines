source("src/000_setup.R")

fetch_gmw <- function(x, progress = TRUE) {
  with_progress({
    get_resources(x, get_gmw())
  }, enable = progress)
}

stats_gmw <- function(
    x,
    progress = TRUE) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_mangroves_area()
    )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = fetch_gmw,
  calc_stats = stats_gmw,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  out_path = out_path,
  suffix = "gmw-indicators"
)

saveRDS(timings, file.path(out_path, "gmw-timings.rds"))
