# Forgejo Actions runner image - go flavour (B1 layered)
# Inherits BU packages from base-universal image
# Adds: Go 1.26.4 standard toolchain

FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

ARG GO_VERSION=1.26.4
ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN if [ "$TARGETARCH" = "arm64" ]; then \
      GO_ARCH=arm64; \
      GO_SHA256=ef758ae7c6cf9267c9c0ef080b8965f453d89ab2d25d9eb22de4405925238768; \
    else \
      GO_ARCH=amd64; \
      GO_SHA256=1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f; \
    fi \
 && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o /tmp/go.tar.gz \
 && echo "${GO_SHA256}  /tmp/go.tar.gz" | sha256sum -c - \
 && tar -C /usr/local -xzf /tmp/go.tar.gz \
 && rm -f /tmp/go.tar.gz \
 && /usr/local/go/bin/go version \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      g++=4:13.2.0-7ubuntu1 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

LABEL org.opencontainers.image.title="runner-images/go"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Go with standard toolchain"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="go"
LABEL runner.base="base-universal"
LABEL runner.base.tag="1.0.0"

ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DATE_EPOCH=0
ENV PATH="/usr/local/go/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
