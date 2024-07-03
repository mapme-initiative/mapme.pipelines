source("src/000_setup.R")

fetch_hfp <- function(x, progress = TRUE) {
  with_progress({
    get_resources(x, get_humanfootprint(years = 2000:2020))
  }, enable = progress)
}

stats_hfp <- function(
    x,
    progress = TRUE,
    stats = c("min", "mean", "median", "sd", "max", "sum")) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_humanfootprint(engine = "exactextract",
                          stats = stats)
    )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = fetch_hfp,
  calc_stats = stats_hfp,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  batch_size = batch_size,
  out_path = out_path,
  suffix = "hfp-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "hfp-timings.rds"))
