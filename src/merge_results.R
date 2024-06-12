source("src/000_setup.R")

rdsfiles <- dir(out_path, pattern = "*indicator*", ignore.case = TRUE, full.names = TRUE)

if (by_region) {
  rdsfiles <- grep("all", rdsfiles, value = TRUE, invert = TRUE)
} else {
  rdsfiles <- grep("all", rdsfiles, value = TRUE)
}

data <- readRDS(rdsfiles[1])
geoms <- st_geometry(data)
data <- st_drop_geometry(data)
is_list <- sapply(data, is.list)
data <- data[ ,-which(is_list)]
data$geometry <- geoms
data <- st_as_sf(data)

inds <- map(rdsfiles, function(file) {
  d <- readRDS(file)
  d <- st_drop_geometry(d)
  is_list <- sapply(d, is.list)
  ind_cols <- names(d)[is_list]
  d <- d[ ,c("WDPA_PID", ind_cols)]

  if(all(ind_cols == "species_richness")) {
    colname <- tolower(basename(file))
    colname <- strsplit(colname, "-")[[1]][2]
    colname <- gsub("iucn_", "", colname)
    d <- rename(d, !!colname := "species_richness")
  }
  d
})

for (i in 1:length(inds)) data <- as_tibble(merge(data, inds[[i]]))
data <- st_as_sf(data)
data <- mapme.biodiversity:::.geom_last(data)
saveRDS(data, file.path("kfw_portfolio_indicators.rds"))
