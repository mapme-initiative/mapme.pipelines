country_codes <- read.csv("raw/kfw_ipex_portfolio_countries.csv", sep = ",")
country_codes <- tibble::as_tibble(country_codes)
country_codes <- subset(country_codes, fz_info_portfolio == TRUE )
country_codes <- country_codes[ ,c("iso3", "sub_region_name")]
