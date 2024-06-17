FROM ghcr.io/mapme-initiative/mapme-base:1.2.0

LABEL org.opencontainers.image.title="wdpa-pipelines" \
      org.opencontainers.image.licenses="GPL-3.0-or-later" \
      org.opencontainers.image.source="https://github.com/mapme.initiative/wdpa-pipelines" \
      org.opencontainers.image.vendor="MAPME Initiative" \
      org.opencontainers.image.description="A build of pipelines to process WDPA." \
      org.opencontainers.image.authors="Darius Görgen <info@dariusgoergen.com>"

RUN R -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN mkdir /renv
COPY renv.lock /renv/renv.lock
RUN R -e "renv::restore(lockfile = '/renv/renv.lock', library = '/usr/local/lib/R/site-library')"
WORKDIR /home/rstudio
