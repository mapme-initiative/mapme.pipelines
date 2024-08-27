#' Run a MAPME analysis pipeline
#'
#' Analysis pipelines are configured using a YAML configuration file.
#' Its contents will be checked for validity before running any calculations.
#' Resources/indicators top-level objects are their respective functionc calls
#' (e.g. `get_*`/`calc_*`) with optional sub-objects `args` (defining the
#' respective function's arguments) and `options` (see Details below).
#'
#' The required objects are:
#' - input: A charachter pointing to a existing GDAL-readable vector data source
#' - output: A charachter pointing to a non-existing GPGK (unless the overwrite option is set to TRUE)
#' - datadir: A charachter pointing to a GDAL-writable path prefix
#' - resources: At least a single resource `get_*()` function has to be defined with
#'   possible `args` and `options` objects
#' - indicators: At least a single indicator `calc_*()` function has to be defined with
#'   possible `args` and `options` objects
#'
#' Optional objects are:
#' - batchsize: Integer value indicating the batchsize with wich `input` is sliced
#'   into equally sized batches for processing (default: 10,000)
#' - options: An options object set as global options. Each resource/indicator
#'   object can also be supplied with an `options` object to have finer control
#'
#' The following values can be set in `options`:
#' - overwrite: logical, indicating if existing outputs should be overwritten (default: false)
#' - progress: logical, indicating if progress is to be reported (default: false)
#' - maxcores: integer, maximum number of cores for parallel processing (default: 1)
#' - chunksize: numeric, indicating the value for \code{mapme.biodiversity::mapme_options()}
#'   `chunk_size` argument
#' - backend: charachter, either `multisession` or `multicore`, defining the
#'   used parallel backend. Defaults to `multisession` on Windows and interactive sessions,
#'   `multicore` otherwise
#'
#' @param config Path to a `yaml` configuration file (see Details below)
#' @import mapme.biodiversity
#' @export
run_config <- function(config) {
  params <- read_config(config)
  do.call(run, params)
}

run <- function(
    input = NULL,
    output = NULL,
    datadir = "./data",
    options = setup_opts(),
    batchsize = 10000,
    resources = NULL,
    indicators = NULL) {

  stopifnot(spds_exists(input))
  dir.create(datadir, showWarnings = FALSE)

  stopifnot(!spds_exists(output) | options$overwrite == TRUE)
  stopifnot(endsWith(output, ".gpkg"))

  options <- setup_opts(options)
  mapme_options(outdir = datadir)

  resource_funs <- purrr::imap(resources, setup_with_opts, options)
  indicator_funs <- purrr::imap(indicators, setup_with_opts, options)

  # prepare input data
  if (options$progress) {
    logger::log_info(sprintf("Now processing '%s'", basename(input)))
  }

  info <- sf::st_layers(input)
  n_total <- info$features
  batches <- ceiling(n_total / batchsize)

  if (options$progress) {
    logger::log_info(sprintf("Found %s assets.", n_total))
    logger::log_info(sprintf("Processing in %s batches.", batches))
  }

  batch_files <- purrr::map_chr(
    seq_len(batches), function(batch_index){

      if (options$progress) {
        logger::log_info("\n")
        logger::log_info("#################################")
        logger::log_info(sprintf("Start processing of batch %s ...", batch_index))
      }

      run_batch(
        input,
        batch_index,
        batchsize,
        resource_funs,
        indicator_funs,
        options$progress)

    })

  merge_batches(batch_files, output)
}


#' @importFrom tibble as_tibble
run_batch <- function(
    input,
    batch_index,
    batchsize,
    resource_funs,
    indicator_funs,
    progress) {

  batch <- read_batch(input, batch_index, batchsize)
  bboxs <- get_bboxs(batch)

  if (progress) {
    logger::log_info("Fetching ressources...")
  }

  purrr::iwalk(resource_funs, call_resource, batch = bboxs)

  if (progress) {
    logger::log_info("Done!")
    logger::log_info("Calculating indicators...")
  }

  batch_inds <- purrr::imap(indicator_funs, call_indicator, batch = batch)
  batch_inds <- purrr::reduce(batch_inds, dplyr::left_join, by = ".mapmeid")
  is_null <- sapply(batch_inds, function(x) all(is.null(unlist(x))))

  batch <- sf::st_sf(dplyr::left_join(batch, batch_inds))
  dsn <- tempfile(fileext = ".gpkg")
  write_portfolio(batch, dsn = dsn)

  if (progress) {
    logger::log_info("Done!")
  }

  dsn
}

#' @importFrom future plan sequential
call_resource <- function(f, name, batch) {
  fun <- f$fun
  opts <- f$opts

  if (opts$progress) {
    logger::log_info(sprintf("Now fetching resource '%s'...", name))
  }

  if (opts$maxcores > 1) {
    plan(opts$backend, workers = opts$maxcores)
  }
  progressr::with_progress({
    get_resources(batch, fun)
  }, enable = opts$progress)
  plan(sequential)
}

#' @importFrom future plan tweak sequential
call_indicator <- function(f, name, batch) {
  fun <- f$fun
  opts <- f$opts

  if (opts$progress) {
    logger::log_info(sprintf("Now processing indicator '%s'...", name))
  }

  mapme_options(chunk_size = opts$chunksize)

  progressr::with_progress({
    if(nrow(batch) > opts$maxcores * 2 && opts$maxcores > 1) {
      plan(opts$backend, workers = opts$maxcores)
    }
    inds <- calc_indicators(batch, fun)
    plan(sequential)
  }, enable = opts$progress)

  terra::tmpFiles(current = TRUE, orphan = TRUE, old = TRUE, remove = TRUE)
  inds <- sf::st_drop_geometry(inds)
  target_cols <- sapply(inds, is.list)
  # TODO: use assetid when mapme.biodiversity
  # does not overwrite unique ids
  target_cols <- c(".mapmeid", names(target_cols)[target_cols])
  inds[ ,target_cols]
}
