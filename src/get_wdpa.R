source("src/000_setup.R")

baseurl <- "https://pp-import-production.s3-eu-west-1.amazonaws.com/WDPA_WDOECM_%s_Public.zip"

latest_ver <- basename(httr::HEAD("http://wcmc.io/wdpa_current_release")$url)[[1]]
latest_ver <- strsplit(latest_ver, "_")[[1]][3]

if (wdpa_ver == "latest") {
  wdpa_ver <- latest_ver
}

url <- file.path("/vsizip", "/vsicurl", sprintf(baseurl, wdpa_ver))
filename <- sprintf("WDPA_WDOECM_%s_Public.gdb", wdpa_ver)
url <- file.path(url, filename)

if (!spds_exists(url)) {
  stop(paste(
    sprintf("WDAP version '%s' does not seem to exist.\n", wdpa_ver),
    sprintf("Latest version is: '%s'", latest_ver)
  ))
}

layers <- sf::st_layers(url)
layer <- grep("poly", layers$name, value = TRUE)
wdpa_dsn <- file.path(data_path, gsub("gdb", "parquet", basename(url)))

if (!spds_exists(wdpa_dsn)) {
  message("Fetching WDPA data...")
  lcos <- c(
    "-lco", "ROW_GROUP_SIZE=10000",
    "-lco", "WRITE_COVERING_BBOX=YES",
    "-lco", "SORT_BY_BBOX=YES"
  )
  sf::gdal_utils("vectortranslate", source = url, destination = wdpa_dsn,
                 options = c(layer, "-progress", "-makevalid",
                             "-wrapdateline", "-datelineoffset", "180",
                             lcos),
                 quiet = FALSE)
  data <- read_sf(wdpa_dsn, check_ring_dir = TRUE)
  is_valid <- st_is_valid(data)
  invalid <- which(!is_valid)
  data[invalid, ] <- st_make_valid(data[invalid, ])
  invalid <- which(!st_is_valid(data[invalid, ]))

  message(sprintf("From total %s geometries, %s were invalid.\nCould not repair %s geometries.",
                  nrow(data), sum(!is_valid), length(invalid)))

  if (length(invalid) > 0 ) data <- data[-invalid, ]

  st_write(data, wdpa_dsn, layer_options = lcos[c(FALSE, TRUE)], driver = "Parquet")
}
