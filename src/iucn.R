source("src/000_setup.R")

sr_files <- list.files(path = "raw", pattern = "*_SR_*", full.names = TRUE)

fetch_iucn <- function(x, progress = TRUE, paths = sr_files) {
  get_resources(x, get_iucn(paths = paths))
}


stats_iucn <- function(
    x,
    progress = TRUE,
    stats = c("min", "mean", "median", "sd", "max")) {

  with_progress({
    inds <- calc_indicators(
      x,
      calc_species_richness(engine = "extract",
                            stats = stats))
  }, enable = progress)
  inds
}

timings <- run_indicator(
  input = input,
  fetch_resources = fetch_iucn,
  calc_stats = stats_iucn,
  resource_cores = 10,
  ncores = ncores,
  progress = progress,
  area_threshold = 5000000,
  out_path = out_path,
  suffix = "iucn-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "iucn-timings.rds"))
