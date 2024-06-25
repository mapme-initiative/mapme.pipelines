source("src/000_setup.R")

fetch_dem <- function(x, progress = TRUE) {
  with_progress({
    get_resources(x, get_nasa_srtm())
  }, enable = progress)
}


stats_dem <- function(x, progress = TRUE, stats = c("min", "mean", "median", "sd", "max")) {
  with_progress({
      inds <- calc_indicators(
        x,
        calc_elevation(engine = "exactextract", stats = stats),
        calc_tri(engine = "exactextract", stats = stats)
      )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = fetch_dem,
  calc_stats = stats_dem,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  out_path = out_path,
  suffix = "dem-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "dem-timings.rds"))
