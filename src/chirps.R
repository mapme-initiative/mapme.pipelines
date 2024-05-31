source("src/000_setup.R")

plan(multicore(workers =  min(10, ncores)))
with_progress({
  get_resources(
    aoi,
    get_chirps(1981:2022)
  )
}, enable = TRUE)
plan(sequential)

with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_precipitation_chirps(years = 1981:2022, engine = "exactextract")
    )
  })
}, enable = TRUE)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "precipitation_indicators.rds"))

