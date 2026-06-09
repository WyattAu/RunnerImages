# Forgejo Actions runner image - heavy flavour
# Layer count: 2 (bu-base + heavy)
# BU packages from base-universal, Node.js + Python + Docker CLI

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Heavy additions (Node + Python + Docker CLI)
# ---------------------------------------------------------------------------
FROM bu-base AS heavy

ARG NODE_VERSION=22.22.3
ARG IMAGE_VERSION=dev
ARG TARGETARCH

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
      python3=3.12.3-0ubuntu2.1 \
      python3-pip=24.0+dfsg-1ubuntu1.3 \
      python3-venv=3.12.3-0ubuntu2.1 \
      python3-dev=3.12.3-0ubuntu2.1 \
      libffi-dev=3.4.6-1build1 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
      iputils-ping=3:20240117-1ubuntu0.1 \
      net-tools=2.10-0.1ubuntu4.4 \
 && apt-get purge -y gnupg \
 && apt-get autoremove -y \
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
 && npm install -g yarn pnpm \
 && yarn --version \
 && pnpm --version \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/heavy"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Node.js + Python + Docker CLI for monorepos"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="heavy"
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
