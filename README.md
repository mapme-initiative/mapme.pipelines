<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
[![R-CMD-check](https://github.com/mapme-initiative/wdpa-pipelines/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mapme-initiative/wdpa-pipelines/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

# mapme.pipelines

The codes in this repository are currently WIP. The goal of this project
is to conduct large-scale analysis of globally distributed portfolios
based on reproducible pipelines powered by `{mapme.biodiversity}`.

To reduce the production of boilerplate code when using conducting
analysis with `mapme.biodiversity` one can instead produce a high-level
YAML file indicating input/output files, options as well as which
resources to fetch and indicators to calculate. 

To install the package run:

```r
remotes::install_github("mapme-initiative/mapme.pipelines")
```

The package exports a single function called `run_config()`
which you should point towards a `YAML` file. Suppose
you wanted to run the `calc_treecover_area()` indicator
for a GeoPackage called `my-polygons.gpkg`, the yaml 
should look something like this:

```yaml
input: ./my-polygons.gpkg
output: ./my-polygons-treecover.gpkg
datadir: ./data
options:
  maxcores: 4
  progress: true
  chunksize: 50000
resources:
  get_gfw_treecover:
    args:
      version: GFC-2023-v1.11
  get_gfw_lossyear:
    args: 
      version: GFC-2023-v1.11
indicators:
  calc_treecover_area:
    args: 
      min_cover: 30
      min_size: 1
```

Putting the content above in a file called `config.yaml`,
all we have to do to run the configured pipeline is:

```r
library(mapme.biodiversity)
library(mapme.pipelines)
run_config("./config.yaml")
```

See `help(run_config)` for additional details how to customize
your pipeline.
