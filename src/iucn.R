source("src/000_setup.R")

sr_files <- list.files(file.path(data_path, "iucn"), full.names = TRUE)
sr_types <- tools::file_path_sans_ext(tolower(basename(sr_files)))


purrr::walk(seq_along(sr_files), function(i) {


  fetch_iucn <- function(x, progress = TRUE, path = sr_files[i]) {
    get_resources(x, get_iucn(path = path))
  }

  stats_iucn <- function(
    x,
    progress = TRUE,
    stats = c("min", "mean", "median", "sd", "max"),
    variable = sr_types[i]) {

    with_progress({
      inds <- calc_indicators(
        x,
        calc_species_richness(engine = "extract",
                              stats = stats,
                              variable = variable))
    }, enable = progress)

    inds
  }

  timings <- run_indicator(
    country_codes = country_codes,
    wdpa_src = wdpa_dsn,
    layer = layer,
    fetch_resources = fetch_iucn,
    calc_stats = stats_iucn,
    resource_cores = 10,
    ncores = ncores,
    progress = progress,
    area_threshold = 500000,
    out_path = out_path,
    suffix = paste0("iucn_", sr_types[i], "-indicators")
  )

  saveRDS(timings, file.path(out_path, paste0("iucn_", sr_types[i], "-timings.rds")))
})
