source("src/000_setup.R")

plan(multicore(workers = min(10, ncores)))
with_progress({
  get_resources(
    aoi,
    get_gfw_treecover(version = "GFC-2022-v1.10"),
    get_gfw_lossyear(version = "GFC-2022-v1.10"),
    get_gfw_emissions()
  )
}, enable = TRUE)
plan(sequential)

plan(list(tweak(multicore, workers = ncores), sequential))
with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_treecover_area_and_emissions(years = 2000:2022, min_size = 1, min_cover = 30)
    )
  })
}, enable = TRUE)
plan(sequential)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "gfw_indicators.rds"))

