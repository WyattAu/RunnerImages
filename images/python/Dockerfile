# Forgejo Actions runner image - python flavour
# Layer count: 2 (bu-base + python)
# BU packages from base-universal, Python 3.12 + pip + venv + g++ + dev headers

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Python-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS python

ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      g++ \
      python3 \
      python3-pip \
      python3-venv \
      python3-dev \
      libffi-dev \
      libssl-dev \
      sudo \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/python"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Python 3.12 with pip, venv, and native extension support"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="python"
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
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
