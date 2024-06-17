
<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

# wdpa-pipelines

The codes in this repository are currently WIP. The goal of this project
is to conduct large-scale analysis of globally distributed portfolios
based on the World Database on Protected Areas (WDPA) with `{mapme.biodiversity}`.

To make this project work on your local machine, first open up the setup
file and adjust according to your requirements.

```r
file.edit("src/000_setup")
```

You can build a docker image for the project via:

```bash
docker build -t wdpa-pipelines:latest .
```

Then, to calculate e.g. forest cover and emission indicators you can issue
the following command in a shell on a Unix system from the project's root 
directory:

```console
$ docker run -v .:/home/rstudio wdpa-pipelines:latest Rscript src/gfw.R
```

Note, this will map the project directory into the docker container. In 
case your input/output directories are elsewhere on your machine make sure
to map those locations correctly to the container, too.
