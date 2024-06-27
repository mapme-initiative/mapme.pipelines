source("src/000_setup.R")

get_landcover <- function(x, progress = TRUE) {
  with_progress({
    get_resources(
      x,
      get_esalandcover()
    )
  }, enable = progress)
}

stats_landcover <- function(x, progress = TRUE) {
  with_progress({
      inds <- calc_indicators(
        x,
        calc_landcover()
      )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = get_landcover,
  calc_stats = stats_landcover,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 75000,
  out_path = out_path,
  suffix = "landcover-indicators",
  overwrite =  overwrite
)

saveRDS(timings, file.path(out_path, "landcover-timings.rds"))
