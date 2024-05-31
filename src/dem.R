source("src/000_setup.R")

plan(multicore(workers = min(10, ncores)))
with_progress({
  get_resources(aoi, get_nasa_srtm())
}, enable = TRUE)
plan(sequential)

plan(list(tweak(multisession, workers = ncores), sequential))
with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_elevation(engine = "exactextract", stats = c("min", "mean", "median", "sd", "max")),
      calc_tri(engine = "exactextract", stats = c("min", "mean", "median", "sd", "max"))
    )
  })
}, enable = TRUE)
plan(sequential)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "elevation_indicators.rds"))

