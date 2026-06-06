# Forgejo Actions Runner Image: ubuntu
# 3-layer architecture: base → bu-base → ubuntu
# Verified: UP1-UP10, C1-C12, S1-S10

# =============================================================================
# Layer 0: Base image (pinned by digest)
# =============================================================================
FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS base

# =============================================================================
# Layer 1: BU base packages (shared across ALL flavours)
# =============================================================================
FROM base AS bu-base

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # VCS
    git \
    git-lfs \
    openssh-client \
    # Build
    make \
    build-essential \
    # Data
    jq \
    # HTTP
    curl \
    wget \
    # Archive
    zip \
    unzip \
    zstd \
    tar \
    gzip \
    # Crypto
    ca-certificates \
    openssl \
    # System
    diffutils \
    patch \
    file \
    tree \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/*

# =============================================================================
# Layer 2: Ubuntu-specific additions
# =============================================================================
FROM bu-base AS ubuntu

# Add Docker APT repository
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
  && install -m 0755 -d /etc/apt/keyrings \
  && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
  && chmod a+r /etc/apt/keyrings/docker.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    # Docker CLI (for DinD workflows)
    docker-ce-cli \
    # Build extras
    g++ \
    pkg-config \
    libssl-dev \
    # System
    sudo \
    iputils-ping \
    net-tools \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/*

# =============================================================================
# User setup (final stage only)
# Remove default ubuntu user (UID 1000), create runner as UID 1000
# =============================================================================
RUN userdel -r ubuntu 2>/dev/null || true \
  && groupdel ubuntu 2>/dev/null || true \
  && groupadd -g 1000 runner \
  && useradd -u 1000 -g 1000 -m -s /bin/bash runner \
  && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner

ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER runner
WORKDIR /home/runner

ENTRYPOINT ["/bin/bash"]
