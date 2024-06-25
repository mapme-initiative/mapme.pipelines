source("src/000_setup.R")

get_gsw <- function(x, progress = TRUE) {
  with_progress({
    get_resources(
      x,
      get_gsw_time_series(years = 1984:2021, version = "VER5-0")
    )
  }, enable = progress)
}

stats_gsw <- function(x, progress = TRUE) {
  with_progress({
      inds <- calc_indicators(
        x,
        calc_gsw_time_series(years = 1984:2021)
      )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = get_gsw,
  calc_stats = stats_gsw,
  resource_cores = 6,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  out_path = out_path,
  suffix = "gsw-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "gsw-timings.rds"))
