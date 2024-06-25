source("src/000_setup.R")

pattern <- make_filename(input, out_path, suffix = "*")
pattern <- tools::file_path_sans_ext(basename(pattern))
gpkgs <- list.files(path = out_path, pattern = pattern, full.names = TRUE)

data <- purrr::map(gpkgs, function(x) as_tibble(read_portfolio(x)))
data <- purrr::reduce(data, full_join)
data <- st_sf(data)
data <- mapme.biodiversity:::.geom_last(data)

filename <- make_filename(input, out_path, suffix = "combined")
write_portfolio(data, filename, delete_dsn = overwrite)
