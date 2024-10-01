order_parallel <- function(x, ncores = 4, areas = NULL, decreasing = TRUE) {
  if (nrow(x) == 0) return(NULL)
  stopifnot(length(ncores) == 1 && is.numeric(ncores))
  stopifnot(is.null(areas) | (is.numeric(areas) & length(areas) == nrow(x)))
  if (is.null(areas)) {
    areas <- lapply(sf::st_geometry(x), function(y) sf::st_area(sf::st_as_sfc(sf::st_bbox(y))))
    areas <- do.call("c", areas)
  }
  bboxs_ordered <- order(areas, decreasing = TRUE)
  index <- rep(1:ncores, round(length(areas) / ncores))[1:length(areas)]
  index <- order(index, decreasing = decreasing)
  x[bboxs_ordered[index], ]
}

split_aoi <- function(x, areas, thres, ncores, decreasing = TRUE) {

  stopifnot(length(ncores) == 2)
  stopifnot(length(areas) == nrow(x) && is.numeric(areas))
  stopifnot(length(thres) == 1 && is.numeric(thres))
  stopifnot(is.logical(decreasing))

  areas <- as.numeric(areas)
  thres <- as.numeric(thres)

  small <- large <- NULL

  x_small <- x[areas <= thres, ]
  a_small <- areas[areas <= thres]
  x_large <- x[areas > thres, ]
  a_large <- areas[areas > thres]

  x_small <- order_parallel(x_small, ncores[1], a_small, decreasing)
  x_large <- order_parallel(x_large, ncores[2], a_large, decreasing)

  list(small=x_small,large=x_large)

}

validate <- function(data,
  schema = system.file("schema.yaml", package = "mapme.pipelines"),
  ...) {
  s <- yaml::read_yaml(schema)
  s <- jsonlite::toJSON(s, auto_unbox = TRUE, null = "null")

  d <- yaml::read_yaml(data)
  d <- jsonlite::toJSON(d, auto_unbox = TRUE, null = "null")

  jsonvalidate::json_validate(d, s, ...)
}

read_config <- function(path = character(0)) {
  stopifnot(is.character(path) && tools::file_ext(path) == "yaml")
  is_valid <- suppressWarnings(validate(path, verbose = TRUE, engine = "ajv"))
  if (!is_valid) {
    errors <- attr(is_valid, "errors")
    msg <- paste0('In "', errors$instancePath, '":\n',
    errors$message, "\n\n")
    stop(
      "Configuration file is not valid.\n",
      "Found the following errors:\n\n",
      msg)
  }
  yaml::read_yaml(path)
}

setup_with_opts <- function(f, name, options) {
  args <- f$args
  opts <- f$options
  f <- setup(name, args)
  opts <- override_opts(opts, options)
  list(fun = f, opts = opts)
}

setup <- function(name, args = list()) {
  if (is.null(args)) args <- list()
  f <- match.fun(name)
  f <- do.call(f, args)
  f
}

read_batch <- function(src, batch_index, batchsize) {
  info <- sf::st_layers(src)
  layer <- info[["name"]][1]
  ntotal <- info[["features"]][1]

  offset <- (batch_index - 1) * batchsize
  if (offset > ntotal) return(NULL)

  query <- "select * from %s limit %s offset %s"
  query <- sprintf(query, layer, batchsize, offset)

  data <- sf::read_sf(src, query = query)
  # TODO: use assetid when upstream mapme.biodiversity
  # does not override it
  ids <- seq(offset + 1, offset + nrow(data))
  data[".mapmeid"] <- ids
  data
}

setup_opts <- function(opts = NULL) {
  defaults <- list(
    overwrite = FALSE,
    progress = FALSE,
    timeout = 600,
    maxcores = 1,
    chunksize = 100000,
    backend = if(interactive() | Sys.info()[["sysname"]] == "Windows") future::multisession else future::multicore
  )
  override_opts(opts, defaults)
}

override_opts <- function(opts = NULL, global_opts) {
  if(is.null(opts)) return(global_opts)
  global_opts[names(opts)] <- opts
  global_opts
}

get_bboxs <- function(x) {
  bboxs <- lapply(sf::st_geometry(x), function(y) sf::st_as_sfc(sf::st_bbox(y)))
  bboxs <- sf::st_sf(do.call("c", bboxs), crs = sf::st_crs(x))
  bboxs[["area"]] <- as.numeric(sf::st_area(bboxs)) / 10000
  sf::st_geometry(bboxs) <- "geometry"
  bboxs
}

merge_batches <- function(paths, filename) {
  data <- purrr::map(paths, function(x) tibble::as_tibble(read_portfolio(x)))
  data <- purrr::list_rbind(data)
  data[["assetid"]] <- data[[".mapmeid"]]
  data[[".mapmeid"]] <- NULL
  write_portfolio(sf::st_sf(data), filename)
  filename
}
