# Forgejo Actions runner image - ubuntu flavour
# Layer count: 2 (bu-base + ubuntu)
# BU packages from base-universal, Docker CLI + build tools + network utilities

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Ubuntu-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS ubuntu

ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends gnupg=2.4.4-2ubuntu17.4 \
 && install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
 && chmod a+r /etc/apt/keyrings/docker.gpg \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      docker-ce-cli=5:29.5.3-1~ubuntu.24.04~noble \
      g++=4:13.2.0-7ubuntu1 \
      pkg-config=1.8.1-2build1 \
      libssl-dev=3.0.13-0ubuntu3.9 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
      iputils-ping=3:20240117-1ubuntu0.1 \
      net-tools=2.10-0.1ubuntu4.4 \
 && apt-get purge -y gnupg \
 && apt-get autoremove -y \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/ubuntu"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Docker CLI and build tools"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="ubuntu"
LABEL runner.base="base-universal"
LABEL runner.base.tag="1.0.0"

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
