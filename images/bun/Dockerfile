# Forgejo Actions runner image - bun flavour
# Layer count: 2 (bu-base + bun)
# BU packages from base-universal, Bun 1.3.14 + g++ + python3

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Bun-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS bun

ARG BUN_VERSION=1.3.14
ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      g++ \
      python3 \
      sudo \
 && if [ "$TARGETARCH" = "arm64" ]; then \
      BUN_ARCH=aarch64; \
      BUN_SHA256=a27ffb63a8310375836e0d6f668ae17fa8d8d18b88c37c821c65331973a19a3b; \
    else \
      BUN_ARCH=x64; \
      BUN_SHA256=951ee2aee855f08595aeec6225226a298d3fea83a3dcd6465c09cbccdf7e848f; \
    fi \
 && curl -fsSL "https://github.com/oven-sh/bun/releases/latest/download/bun-linux-${BUN_ARCH}.zip" -o /tmp/bun.zip \
 && echo "${BUN_SHA256}  /tmp/bun.zip" | sha256sum -c - \
 && unzip /tmp/bun.zip -d /usr/local \
 && mv /usr/local/bun-linux-${BUN_ARCH}/bun /usr/local/bin/bun \
 && rm -rf /tmp/bun.zip /usr/local/bun-linux-${BUN_ARCH} \
 && chmod +x /usr/local/bin/bun \
 && bun --version \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/bun"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Bun 1.3.14"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="bun"
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
ENV PATH="/home/runner/.bun/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
