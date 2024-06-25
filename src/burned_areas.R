source("src/000_setup.R")

fetch_modis <- function(x, progress = TRUE) {
  with_progress({
    get_resources(x, get_mcd64a1(years = 2000:2022))
  }, enable = progress)
}


stats_burned_area <- function(x, progress = TRUE) {
  with_progress({
      inds <- calc_indicators(
        aoi,
        calc_burned_area(engine = "exactextract")
      )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = fetch_modis,
  calc_stats = stats_burned_area,
  resource_cores = 2,
  ncores = ncores,
  progress = progress,
  area_threshold = 500000,
  out_path = out_path,
  suffix = "burned_area-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "burned_area-timings.rds"))

