source("src/000_setup.R")

get_resources(aoi, get_worldpop(2000:2020))

plan(list(tweak(multisession, workers = ncores), sequential))
with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_population_count(
        engine = "exactextract",
        stats = c("min", "mean", "median", "sd", "max", "sum"))
    )
  })
}, enable = TRUE)
plan(sequential)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "population_indicators.rds"))

