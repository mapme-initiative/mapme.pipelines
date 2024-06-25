source("src/000_setup.R")

get_traveltime <- function(x, progress = TRUE) {
  with_progress({
    get_resources(
      x,
      get_nelson_et_al(c("5k_10k", "10k_20k", "20k_50k", "50k_100k",
                         "100k_200k", "200k_500k", "500k_1mio",
                         "1mio_5mio", "50k_50mio", "5k_110mio",
                         "20k_110mio", "5mio_50mio"))
    )
  }, enable = progress)
}

stats_traveltime <- function(
    x,
    progress = TRUE,
    stats = c("min", "mean", "median", "sd", "max")) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_traveltime(engine = "exactextract", stats = stats)
    )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = get_traveltime,
  calc_stats = stats_traveltime,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 500000,
  out_path = out_path,
  suffix = "traveltime-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "traveltime-timings.rds"))
