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
  input = input,
  fetch_resources = fetch_chirps,
  calc_stats = stats_chirps,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 5000000,
  batch_size = batch_size,
  out_path = out_path,
  suffix = "chirps-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "chirps-timings.rds"))
