# Forgejo Actions runner image - rust flavour (B1 layered)
# Inherits BU packages from base-universal image
# Adds: Rust stable toolchain + cargo + rustup

# ---------------------------------------------------------------------------
# Base: inherit BU packages from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

ARG RUST_VERSION=1.96.0
ARG IMAGE_VERSION=dev

# ---------------------------------------------------------------------------
# Rust-specific additions + sudo (runner user already exists from base)
# ---------------------------------------------------------------------------
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      g++=4:13.2.0-7ubuntu1 \
      pkg-config=1.8.1-2build1 \
      libssl-dev=3.0.13-0ubuntu3.9 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION} --no-modify-path \
 && chmod -R a+rwX /usr/local/cargo /usr/local/rustup \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/rust"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Rust with cargo and rustup"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="rust"
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
ENV PATH="/usr/local/cargo/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
