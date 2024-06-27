source("src/000_setup.R")

fetch_teow <- function(x, progress = TRUE) {
  get_resources(x, get_teow())
}

stats_ecoregion <- function(x, progress = TRUE) {
  with_progress({
    inds <- calc_indicators(x, calc_ecoregion())
  }, enable = progress)
  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = fetch_teow,
  calc_stats = stats_ecoregion,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 5000000,
  out_path = out_path,
  suffix = "ecoregion-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "ecoregion-timings.rds"))
