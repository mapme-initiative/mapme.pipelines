test_that("order parallel works", {
  x = sf::read_sf(system.file("shape/nc.shp", package="sf"))
  x$area <- sf::st_area(x)
  expect_error(order_parallel(x, ncores = x))
  expect_error(order_parallel(x, ncores = c(1:2)))
  expect_error(order_parallel(x, ncores = 2, areas = 1:10))
  expect_silent(x2 <- order_parallel(x, ncores = 2))
  expect_true(inherits(x2, "sf"), nrow(x2) == nrow(x))
})

test_that("split_aoi works", {
  x = sf::read_sf(system.file("shape/nc.shp", package="sf"))
  x$area <- sf::st_area(x)
  expect_error(split_aoi(x))
  expect_error(split_aoi(x, areas = x$area))
  expect_error(split_aoi(x, areas = x$area, thres = median(x$area)))
  expect_error(split_aoi(x, areas = 1:5, thres = median(x$area), ncores = c(2,2)))
  expect_error(split_aoi(x, areas = x$area, thres = "a", ncores = c(2,2)))
  expect_error(split_aoi(x, areas = x$area, thres = median(x$area), ncores = 1))

  expect_silent(s <- split_aoi(x, areas = x$area, thres = median(x$area), ncores = c(2,2)))
  expect_true(inherits(s, "list"), length(s) == 2, identical(names(s), c("small", "large")))
  expect_true(nrow(s[[1]]) == 50)
})


test_that("validate and read_config works", {
  data_file <- system.file("config-example.yaml", package = "mapme.pipelines")
  tmp_file <- tempfile(fileext = ".yaml")
  file.copy(data_file, tmp_file)
  expect_true(validate(tmp_file))
  cnt <- readLines(tmp_file)
  cnt[17] <- "  get_worldpop:"
  writeLines(cnt, tmp_file)
  expect_false(validate(tmp_file))

  expect_error(read_config(tmp_file))
  cnt <- read_config(data_file)
  expect_true(inherits(cnt, "list"), identical(names(cnt), 
  c("input", "data_path", "output_path", "options", "resources", "indicators")))
})


test_that("read_batch works", {
  src <- system.file("shape/nc.shp", package="sf")
  expect_silent(x <- read_batch(src, 1, 10))
  expect_true(nrow(x) == 10)
  expect_silent(x <- read_batch(src, 10, 10))
  expect_true(nrow(x) == 10)
})

test_that("setup_opts works", {
  expect_silent(opts <- setup_opts(opts = NULL))
  nopts <- c("overwrite", "progress", "timeout", "maxcores",
  "chunksize", "batchsize", "backend")
  expect_true(identical(names(opts), nopts))
  opts2 <- setup_opts(opts = list(maxcores = 5))
  expect_equal(opts[["maxcores"]], 1)
  expect_equal(opts2[["maxcores"]], 5)
})
