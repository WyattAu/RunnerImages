# Forgejo Actions runner image - r-lang flavour
# Layer count: 2 (bu-base + r-lang)
# BU packages from base-universal, R + renv + testthat + knitr

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: R-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS r-lang

ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      r-base \
      r-base-dev \
      libcurl4-openssl-dev \
      libssl-dev \
      libxml2-dev \
      sudo \
 && Rscript -e "install.packages(c('renv', 'testthat', 'knitr', 'jsonlite', 'httr', 'curl', 'rprojroot', 'desc', 'pkgload', 'withr'), repos='https://cloud.r-project.org')" \
 && R --version \
 && Rscript -e "cat(paste(installed.packages()[,'Package'], collapse=', '))" \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/r-lang"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: R with devtools, renv, testthat, roxygen2, knitr, rmarkdown"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="r-lang"
LABEL runner.base="base-universal"
LABEL runner.base.tag="2.0.0"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DATE_EPOCH=0
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Size budget
# ---------------------------------------------------------------------------
# COMP_BUDGET=500
# UNCOMP_BUDGET=1500

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
