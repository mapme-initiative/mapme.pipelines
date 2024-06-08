
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

# wdpa-pipelines

The codes in this repository are currently WIP. The goal of this project
is to conduct large-scale analysis of globally distributed portfolios
based on the World Database on Protected Areas (WDPA) with `{mapme.biodiversity}`.

To make this project work on your local machine, first open up the setup
file via:

```r
file.edit("src/000_setup")
```

and adjust according to your requirements.

To then calculate e.g. forest cover and emission indicators you can issue
the following command in a shell on a Unix system from the project's root 
directory:

```console
foo@bar:~/mapme.pipelines$ Rscript src/gfw.R
```
