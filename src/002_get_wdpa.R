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
wdpa_dsn <- file.path(data_path, gsub("gdb", "gpkg", basename(url)))

if (!spds_exists(wdpa_dsn)) {
  message("Fetching WDPA data...")
  sf::gdal_utils("vectortranslate", source = url, destination = wdpa_dsn,
                options = c("-progress", "-wrapdateline",
                            "-datelineoffset", "180", "-makevalid"),
                quiet = FALSE)
}
