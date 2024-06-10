filter_gpgk <- function(src, layer, isos) {
  read_sf(
    src, check_ring_dir = TRUE,
    query = sprintf(
      "select * from '%s' where ISO3 in(%s) and MARINE in('0','1');",
      layer, isos))
}

order_parallel <- function(x, ncores = 4, bboxs = NULL, decreasing = TRUE) {
  if (nrow(x) == 0) return(NULL)
  stopifnot(is.numeric(ncores) || length(ncores) == 1)
  stopifnot(is.null(bboxs) || is.numeric(bboxs))
  if (is.null(bboxs)) {
    bboxs <- sapply(1:nrow(x), function(i) st_area(st_as_sfc(st_bbox(x[i,]))))
  }
  bboxs_ordered <- order(bboxs, decreasing = TRUE)
  index <- rep(1:ncores, round(length(bboxs) / ncores))[1:length(bboxs)]
  index <- order(index, decreasing = decreasing)
  x[bboxs_ordered[index], ]
}

split_aoi <- function(x, areas, thres, ncores) {

  small <- large <- NULL

  small <- x[areas <= thres, ]
  large <- x[areas > thres, ]

  small <- order_parallel(small, ncores = ncores[1])
  large <- order_parallel(large, ncores = ncores[2])

  list(small=small,large=large)

}


run_indicator <- function(
    country_codes,
    wdpa_src,
    layer,
    fetch_resources,
    calc_stats,
    resource_cores = 10,
    ncores = 10,
    progress = TRUE,
    area_threshold = 90000,
    out_path = ".",
    suffix = "") {

  # check inputs
  stopifnot(inherits(country_codes, "data.frame") && identical(names(country_codes), c("iso3", "sub_region_name")))
  stopifnot(is.character(wdpa_src) && length(wdpa_src) == 1 && spds_exists(wdpa_src))
  stopifnot(is.character(layer) && length(layer) == 1)
  stopifnot(inherits(fetch_resources, "function"))
  stopifnot(inherits(calc_stats, "function"))
  stopifnot(inherits(resource_cores, "numeric") && length(resource_cores) == 1)
  stopifnot(inherits(ncores, "numeric") && length(ncores) == 1)
  stopifnot(inherits(progress, "logical"))
  stopifnot(inherits(area_threshold, "numeric") && length(area_threshold) == 1)
  stopifnot(is.character(out_path) && length(out_path) == 1)
  stopifnot(is.character(suffix) && length(suffix) == 1)

  timings <- purrr::map_dfr(unique(country_codes$sub_region_name), function(region) {

    null_result <- data.frame(region = region, n = 0, timing = 0)
    filename <- paste0(paste(gsub(" ", "_", tolower(region)), suffix, sep = "-"), ".rds")
    filename <- file.path(out_path, filename)
    if (file.exists(filename)) return(null_result)

    if (progress) {
      print(Sys.time())
      print(sprintf("Now processing %s", region))
    }

    isos <- country_codes$iso3[country_codes$sub_region_name == region]
    isos <- paste(sprintf("'%s'", isos), collapse = ",")
    x <- filter_gpgk(wdpa_src, layer, isos)


    if (nrow(x) == 0) return(null_result)

    x <- st_make_valid(x)
    is_valid <- st_is_valid(x)
    x_valid <- x[is_valid, ]

    if (nrow(x_valid) == 0) return(null_result)

    if (progress) {
      print(sprintf("Found %s assets...", nrow(x)))
    }

    bboxs <- purrr::map_dfr(1:nrow(x_valid), function(i) st_as_sf(st_as_sfc(st_bbox(x_valid[i, ]))))
    bboxs <- st_as_sf(bboxs)
    bbox_areas <- as.numeric(st_area(bboxs)) / 10000

    # fetch resources
    plan(multicore, workers = min(ncores, resource_cores))
    res <- try(fetch_resources(bboxs, progress))
    plan(sequential)

    if (inherits(res, "try-error")) return(null_result)

    inds_small <- inds_large <- NULL

    x_split <- split_aoi(x_valid, bbox_areas, area_threshold, ncores = c(ncores, 2))
    mapme_options(chunk_size = area_threshold)

    start <- Sys.time()

    if (progress) {
      print("Start time of processing:")
      print(start)
      n_small <- ifelse(is.null(x_split$small), 0, nrow(x_split$small))
      n_large <- ifelse(is.null(x_split$large), 0, nrow(x_split$large))
      print(sprintf("Number of small assets: %s", n_small))
      print(sprintf("Number of large assets: %s", n_large))
    }

    if(!is.null(x_split$small)){
      if(nrow(x_split$small) > ncores * 2) {
        plan(list(tweak(multicore, workers = ncores), sequential))
      }
      inds_small <- calc_stats(x_split$small, progress = TRUE)
      plan(sequential)
    }

    if(!is.null(x_split$large)){
      plan(list(sequential, tweak(multicore, workers = ncores)))
      inds_large <- calc_stats(x_split$large, progress = TRUE)
      plan(sequential)
    }

    inds <- rbind(inds_small, inds_large)

    saveRDS(inds, filename)

    end <- Sys.time()

    if (progress) {
      print("End time of processing:")
      print(end)
      print("Processing time:")
      print(end-start)
    }

    diff <- end-start
    units(diff) <- "secs"
    result <- data.frame(region = region, n = nrow(x_valid), timing = diff)
    return(result)

  })

  timings
}
