source("src/000_setup.R")

fetch_worldpop <- function(x, progress = TRUE) {
  get_resources(x, get_worldpop(2000:2020))
}

stats_worlpop <- function(
    x,
    progress = TRUE,
    stats = c("min", "mean", "median", "sd", "max", "sum")) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_population_count(
        engine = "exactextract",
        stats = stats)
    )
  }, enable = progress)

  inds
}

timings <- run_indicator(
  country_codes = country_codes,
  wdpa_src = wdpa_dsn,
  layer = layer,
  fetch_resources = fetch_worldpop,
  calc_stats = stats_worlpop,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 500000,
  out_path = out_path,
  suffix = "worldpop-indicators"
)

saveRDS(timings, file.path(out_path, "worldpop-timings.rds"))
