# Forgejo Actions runner image - rust-full flavour
# Layer count: 2 (bu-base + rust-full)
# BU packages from base-universal, Rust + cargo + rustup + wasm-pack + cross + protobuf + cmake + sqlx-cli

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Rust-full specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS rust-full

ARG RUST_VERSION=1.96.0
ARG IMAGE_VERSION=dev
ARG TARGETARCH

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      g++=4:13.2.0-7ubuntu1 \
      pkg-config=1.8.1-2build1 \
      libssl-dev=3.0.13-0ubuntu3.9 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
      protobuf-compiler \
      libsqlite3-dev \
      cmake \
 && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION} --no-modify-path \
 && export PATH="/usr/local/cargo/bin:$PATH" \
 && chmod -R a+rwX /usr/local/cargo /usr/local/rustup \
 && curl -sSf https://rustwasm.github.io/wasm-pack/installer/init.sh | sh \
 && if [ "$TARGETARCH" = "amd64" ]; then \
      curl -sL "https://github.com/cross-rs/cross/releases/latest/download/cross-x86_64-unknown-linux-musl.tar.gz" \
        | tar xz -C /usr/local/cargo/bin cross \
      && chmod +x /usr/local/cargo/bin/cross; \
    fi \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/rust-full"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Rust with cargo, rustup, wasm-pack, cross, protobuf, cmake"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="rust-full"
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
