# Forgejo Actions runner image - rust-node flavour
# Layer count: 2 (bu-base + rust-node)
# BU packages from base-universal, Node.js 22 LTS + Rust stable + cargo + npm + yarn + pnpm
# This is the recommended general-purpose image for repos needing both Node and Rust.

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Rust + Node additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS rust-node

ARG NODE_VERSION=22.22.3
ARG RUST_VERSION=1.96.0
ARG IMAGE_VERSION=dev
ARG TARGETARCH

ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      g++ \
      pkg-config \
      libssl-dev \
      python3 \
      sudo \
# --- Install Node.js ---
 && if [ "$TARGETARCH" = "arm64" ]; then \
      NODE_ARCH=arm64; \
      NODE_SHA256=1c4a9933a5e45bc88f54f70b5f91232c127ec49f1a5989d23fb85824c7adf9b7; \
    else \
      NODE_ARCH=x64; \
      NODE_SHA256=2e5d13569282d016861fae7c8f935e741693c269101a5bebcf761a5376d1f99f; \
    fi \
 && curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${NODE_ARCH}.tar.xz" -o /tmp/node.tar.xz \
 && echo "${NODE_SHA256}  /tmp/node.tar.xz" | sha256sum -c - \
 && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
 && rm -f /tmp/node.tar.xz \
 && node --version | grep -q "v${NODE_VERSION}" \
# --- Install npm global packages ---
 && npm install -g yarn pnpm \
 && yarn --version \
 && pnpm --version \
# --- Install Rust toolchain ---
 && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
      --default-toolchain ${RUST_VERSION} \
      --no-modify-path \
      -c rustfmt \
      -c clippy \
 && chmod -R a+rwX /usr/local/cargo /usr/local/rustup \
# --- Verify Rust ---
 && /usr/local/cargo/bin/rustc --version | grep -q "${RUST_VERSION}" \
 && /usr/local/cargo/bin/cargo --version \
 && /usr/local/cargo/bin/rustfmt --version \
 && /usr/local/cargo/bin/cargo-clippy --version \
# --- Sudo for runner user ---
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/rust-node"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Node.js 22 LTS + Rust stable with cargo, rustfmt, clippy, npm, yarn, pnpm"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="rust-node"
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
ENV PATH="/usr/local/cargo/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
