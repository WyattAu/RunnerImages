# Forgejo Actions runner image - flutter flavour
# Layer count: 2 (bu-base + flutter)
# BU packages from base-universal, Flutter SDK + Dart + build tools

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Flutter-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS flutter

ARG FLUTTER_VERSION=3.44.1
ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      cmake \
      ninja-build \
      g++=4:13.2.0-7ubuntu1 \
      pkg-config=1.8.1-2build1 \
      clang \
      libgtk-3-dev \
      libglu1-mesa \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && curl -fsSL "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" -o /tmp/flutter.tar.xz \
 && mkdir -p /opt/flutter \
 && tar -xJf /tmp/flutter.tar.xz -C /opt --strip-components=1 \
 && rm -f /tmp/flutter.tar.xz \
 && /opt/flutter/bin/flutter config --no-analytics \
 && /opt/flutter/bin/flutter --version \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/flutter"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Flutter SDK with Dart and build tools"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="flutter"
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
ENV PATH="/home/runner/.local/bin:/opt/flutter/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
