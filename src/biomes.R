source("src/000_setup.R")

fetch_teow <- function(x, progress = TRUE) {
  get_resources(x, get_teow())
}

stats_biome <- function(x, progress = TRUE) {
  with_progress({
    inds <- calc_indicators(x, calc_biome())
  }, enable = progress)
  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = fetch_teow,
  calc_stats = stats_biome,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 5000000,
  out_path = out_path,
  suffix = "biome-indicators"
)

saveRDS(timings, file.path(out_path, "biome-timings.rds"))
