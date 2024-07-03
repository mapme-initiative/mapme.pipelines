order_parallel <- function(x, ncores = 4, areas = NULL, decreasing = TRUE) {
  if (nrow(x) == 0) return(NULL)
  stopifnot(is.numeric(ncores) || length(ncores) == 1)
  stopifnot(is.null(areas) || is.numeric(areas))
  if (is.null(areas)) {
    areas <- lapply(st_geometry(x), function(y) st_area(st_as_sfc(st_bbox(y))))
    areas <- do.call("c", areas)
  }
  bboxs_ordered <- order(areas, decreasing = TRUE)
  index <- rep(1:ncores, round(length(areas) / ncores))[1:length(areas)]
  index <- order(index, decreasing = decreasing)
  x[bboxs_ordered[index], ]
}


split_aoi <- function(x, areas, thres, ncores, decreasing = TRUE) {

  small <- large <- NULL

  x_small <- x[areas <= thres, ]
  a_small <- areas[areas <= thres]
  x_large <- x[areas > thres, ]
  a_large <- areas[areas > thres]

  x_small <- order_parallel(x_small, ncores[1], a_small, decreasing)
  x_large <- order_parallel(x_large, ncores[2], a_large, decreasing)

  list(small=x_small,large=x_large)

}

make_filename <- function(input, out_path, suffix) {
  filename <- gsub(" ", "_", tolower(basename(input)))
  filename <- tools::file_path_sans_ext(filename)
  file.path(out_path, paste0(paste(filename, suffix, sep = "-"), ".gpkg"))
}


.process <- function(
    x,
    ncores,
    resource_cores,
    area_threshold,
    fetch_resources,
    calc_stats,
    progress) {

  backend <- if(interactive()) multisession else multicore

  bboxs <- lapply(st_geometry(x), function(y) st_as_sfc(st_bbox(y)))
  bboxs <- st_sf(do.call("c", bboxs), crs = st_crs(x))
  bbox_areas <- as.numeric(st_area(bboxs)) / 10000

  plan(backend, workers = min(ncores, resource_cores))
  res <- try(fetch_resources(bboxs, progress))
  plan(sequential)

  if (inherits(res, "try-error")) return(null_result)

  inds_small <- inds_large <- NULL

  x_split <- split_aoi(x, bbox_areas, area_threshold, ncores = c(ncores, 1))
  mapme_options(chunk_size = area_threshold)

  if(!is.null(x_split$small)){
    if(nrow(x_split$small) > ncores * 2) {
      plan(list(tweak(backend, workers = ncores), sequential))
    }
    inds_small <- calc_stats(x_split$small, progress = progress)
    plan(sequential)
  }

  if(!is.null(x_split$large)){
    plan(list(sequential, tweak(backend, workers = ncores)))
    inds_large <- calc_stats(x_split$large, progress = progress)
    plan(sequential)
  }

  rbind(inds_small, inds_large)
}


run_indicator <- function(
    input,
    fetch_resources,
    calc_stats,
    resource_cores = 10,
    ncores = 10,
    progress = TRUE,
    area_threshold = 90000,
    batch_size = 10000,
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
    message(Sys.time())
    message(sprintf("Now processing %s", basename(input)))
  }

  info <- st_layers(input)
  n_total <- info$features
  layer <- info$name[1]
  batches <- ceiling(n_total / batch_size)

  if (progress) {
    message(sprintf("Found %s assets.", n_total))
    message(sprintf("Processing in %s batches.", batches))
  }

  start <- Sys.time()

  if (progress) {
    print("Start time of processing:")
    print(start)
  }

  inds <- purrr::map(seq_len(batches), function(i) {

    if (progress) {
      message(sprintf("Start of processing batch %s...", i))
    }

    offset <- max(0, ((i * batch_size) - batch_size) - 1)

    query <- "select * from %s limit %s offset %s"
    query <- sprintf(query, layer, batch_size, offset)
    x <- read_sf(input, query = query)

    .process(
      x,
      ncores = ncores,
      resource_cores = resource_cores,
      area_threshold = area_threshold,
      fetch_resources = fetch_resources,
      calc_stats = calc_stats,
      progress = progress)
  })

  inds <- st_as_sf(purrr::list_rbind(inds))

  end <- Sys.time()

  if (progress) {
    print("End time of processing:")
    print(end)
    print("Processing time:")
    print(end-start)
  }

  write_portfolio(inds, filename, quiet = TRUE, overwrite = overwrite)

  diff <- end-start
  units(diff) <- "secs"
  result <- data.frame(region = basename(input), n = n_total, timing = diff)
  return(result)
}
