source("src/000_setup.R")

get_carbon <- function(x, progress) {
  with_progress({
    get_resources(x,
                  get_irr_carbon(),
                  get_vul_carbon(),
                  get_man_carbon()
    )
  }, enable = progress)
}

calc_carbon <- function(x, progress = TRUE,
                         stats = c("min", "mean", "median", "sd", "max")) {
  with_progress({
    inds <- calc_indicators(
      x,
      calc_irr_carbon(type = "all", engine = "exactextract", stats = stats),
      calc_vul_carbon(type = "all", engine = "exactextract", stats = stats),
      calc_man_carbon(type = "all", engine = "exactextract", stats = stats)
    )
  }, enable = progress)

  inds

}

timings <- run_indicator(
  input = input,
  fetch_resources = get_carbon,
  calc_stats = calc_carbon,
  resource_cores = 6,
  ncores = ncores,
  progress = progress,
  area_threshold = 500000,
  out_path = out_path,
  suffix = "carbon-indicators",
  overwrite = overwrite
)

saveRDS(timings, file.path(out_path, "carbon-timings.rds"))
