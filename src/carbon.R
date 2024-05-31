source("src/000_setup.R")

plan(multicore(workers = min(10, ncores)))
with_progress({
  get_resources(aoi,
                get_irr_carbon(),
                get_vul_carbon(),
                get_man_carbon()
  )
}, enable = TRUE)
plan(sequential)

plan(list(tweak(multisession, workers = ncores), sequential))
with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_irr_carbon(type = "all", engine = "exactextract", stats = c("min", "mean", "median", "sd", "max")),
      calc_vul_carbon(type = "all", engine = "exactextract", stats = c("min", "mean", "median", "sd", "max")),
      calc_man_carbon(type = "all", engine = "exactextract", stats = c("min", "mean", "median", "sd", "max"))
    )
  })
}, enable = TRUE)
plan(sequential)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "carbon_indicators.rds"))

