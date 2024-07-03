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
  input = input,
  fetch_resources = fetch_teow,
  calc_stats = stats_biome,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 5000000,
  batch_size = batch_size,
  out_path = out_path,
  suffix = "biome-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "biome-timings.rds"))
