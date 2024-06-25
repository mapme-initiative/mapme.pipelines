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

make_filename <- function(input, out_path, suffix) {
  filename <- gsub(" ", "_", tolower(basename(input)))
  filename <- tools::file_path_sans_ext(filename)
  file.path(out_path, paste0(paste(filename, suffix, sep = "-"), ".gpkg"))
}


run_indicator <- function(
    input,
    fetch_resources,
    calc_stats,
    resource_cores = 10,
    ncores = 10,
    progress = TRUE,
    area_threshold = 90000,
    out_path = ".",
    suffix = "",
    overwrite = FALSE) {

  # check inputs
  stopifnot(is.character(input) && length(input) == 1 && spds_exists(input))
  stopifnot(inherits(fetch_resources, "function"))
  stopifnot(inherits(calc_stats, "function"))
  stopifnot(inherits(resource_cores, "numeric") && length(resource_cores) == 1)
  stopifnot(inherits(ncores, "integer") && length(ncores) == 1)
  stopifnot(inherits(progress, "logical"))
  stopifnot(inherits(area_threshold, "numeric") && length(area_threshold) == 1)
  stopifnot(is.character(out_path) && length(out_path) == 1)
  stopifnot(is.character(suffix) && length(suffix) == 1)

  null_result <- data.frame(filename = basename(input), n = 0, timing = 0)
  filename <- make_filename(input, out_path, suffix)

  if (file.exists(filename) && !overwrite) return(null_result)

  if (progress) {
    print(Sys.time())
    print(sprintf("Now processing %s", basename(input)))
  }

  x <- read_sf(input, check_ring_dir = TRUE)

  if (nrow(x) == 0) return(null_result)

  x <- st_make_valid(x)
  is_valid <- st_is_valid(x)
  x_valid <- x[is_valid, ]

  if (nrow(x_valid) == 0) return(null_result)

  if (progress) {
    print(sprintf("Found %s assets...", nrow(x_valid)))
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

  write_portfolio(inds, filename, quiet = TRUE, overwrite = overwrite)

  end <- Sys.time()

  if (progress) {
    print("End time of processing:")
    print(end)
    print("Processing time:")
    print(end-start)
  }

  diff <- end-start
  units(diff) <- "secs"
  result <- data.frame(region = basename(input), n = nrow(x_valid), timing = diff)
  return(result)

}
