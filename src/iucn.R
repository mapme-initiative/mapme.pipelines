source("src/000_setup.R")

sr_files <- list.files(file.path(data_path, "iucn"), full.names = TRUE)
sr_types <- tools::file_path_sans_ext(tolower(basename(sr_files)))

start <- Sys.time()

purrr::walk(seq_along(sr_files), function(i) {

  get_resources(aoi, get_iucn(path = sr_files[i]))

  plan(list(tweak(multisession, workers = ncores), sequential))
  with_progress({
    sr <- calc_indicators(
      aoi,
      calc_species_richness(engine = "extract",
                            stats = c("min", "mean", "median", "sd", "max"),
                            variable = sr_types[i]))
  }, enable = TRUE)

  plan(sequential)
  saveRDS(sr, file.path(out_path, paste0("iucn_", sr_types[i], ".rds")))
})

end <- Sys.time()

warnings()
print(end-start)




