source("src/000_setup.R")

plan(multicore(workers = minc(10, ncores)))
with_progress({
  get_resources(
    aoi,
    get_nelson_et_al(c("5k_10k", "10k_20k", "20k_50k", "50k_100k",
                       "100k_200k", "200k_500k", "500k_1mio",
                       "1mio_5mio", "50k_50mio", "5k_110mio",
                       "20k_110mio", "5mio_50mio"))
  )
}, enable = TRUE)
plan(sequential)

plan(list(tweak(multicore, workers = ncores), sequential))
with_progress({
  timing <- system.time({
    inds <- calc_indicators(
      aoi,
      calc_traveltime(engine = "exactextract", stats = c("min", "mean", "median", "sd", "max"))
    )
  })
}, enable = TRUE)
plan(sequential)

warnings()
print(timing)

saveRDS(inds, file.path(out_path, "traveltime_indicators.rds"))

