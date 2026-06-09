# Forgejo Actions runner image - nix flavour
# Layer count: 2 (bu-base + nix)
# BU packages from base-universal, Nix package manager (single-user, flake-ready)

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Nix-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS nix

ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      xz-utils \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && groupadd -f nixbld \
 && for i in $(seq 1 10); do useradd -c "Nix build user $i" -d /var/empty -g nixbld -G nixbld -M -N -r -s /usr/sbin/nologin "nixbld$i" 2>/dev/null || true; done \
 && curl -L https://nixos.org/nix/install | sh -s -- --no-daemon \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/nix"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Nix package manager (single-user, flake-ready)"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="nix"
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
ENV NIX_PATH="nixpkgs=channel:nixos-unstable"
ENV PATH="/home/runner/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
