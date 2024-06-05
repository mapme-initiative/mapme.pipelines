source("src/000_setup.R")

get_gfw <- function(x, progress = TRUE) {
  with_progress({
    get_resources(
      x,
      get_gfw_treecover(version = "GFC-2022-v1.10"),
      get_gfw_lossyear(version = "GFC-2022-v1.10"),
      get_gfw_emissions()
    )
  }, enable = progress)
}

stats_gfw <- function(x, progress = TRUE, min_size = 1, min_cover = 3) {
  with_progress({
      inds <- calc_indicators(
        x,
        calc_treecover_area_and_emissions(years = 2000:2022, min_size = min_size, min_cover = min_cover)
      )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = get_gfw,
  calc_stats = stats_gfw,
  resource_cores = 6,
  ncores = ncores,
  progress = progress,
  area_threshold = 50000,
  out_path = out_path,
  suffix = "gfw-indicators"
)

saveRDS(timings, file.path(out_path, "gfw-timings.rds"))

