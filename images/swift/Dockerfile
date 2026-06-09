# Forgejo Actions runner image - swift flavour
# Layer count: 2 (bu-base + swift)
# BU packages from base-universal, Swift 6.3.2 from official tarball

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Swift-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS swift

ARG SWIFT_VERSION=6.1
ARG IMAGE_VERSION=dev
ARG TARGETARCH

# Swift only supports amd64 on Linux (no arm64 tarballs from swift.org)
RUN if [ "$TARGETARCH" != "amd64" ]; then \
      echo "Swift is amd64-only on Linux" && exit 1; \
    fi \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      libncurses5=6.4+20240113-1ubuntu2 \
      libsqlite3-0=3.45.1-1ubuntu2 \
      libpython3.12t64=3.12.* \
      libcurl4t64=8.5.0-2ubuntu10.* \
      libxml2=2.9.14+dfsg-1.3ubuntu3.* \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && SWIFT_TARBALL="swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04" \
 && curl -fsSL "https://download.swift.org/swift-${SWIFT_VERSION}-RELEASE/ubuntu2404/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04.tar.gz" -o /tmp/swift.tar.gz \
 && mkdir -p /tmp/swift-src \
 && tar -xzf /tmp/swift.tar.gz -C /tmp/swift-src --strip-components=1 \
 && cp -a /tmp/swift-src/usr/* /usr/ \
 && rm -rf /tmp/swift.tar.gz /tmp/swift-src \
 && swift --version \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/swift"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Swift with SPM"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="swift"
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
