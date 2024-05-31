source("src/000_setup.R")

plan(multicore(workers = min(2, ncores)))
with_progress({
  get_resources(aoi, get_mcd64a1(years = 2000:2022))
}, enable = TRUE)
plan(sequential)

plan(list(tweak(multisession, workers = ncores), sequential))
with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_burned_area(engine = "exactextract")
    )
  })
}, enable = TRUE)
plan(sequential)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "burned_areas_indicators.rds"))

