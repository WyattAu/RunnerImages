# Forgejo Actions runner image - haskell flavour
# Layer count: 2 (bu-base + haskell)
# BU packages from base-universal, GHC + cabal + stack

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Haskell-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS haskell

ARG GHC_VERSION=9.10.2
ARG CABAL_VERSION=3.14.1.1
ARG STACK_VERSION=3.9.3
ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libgmp-dev \
      libncurses-dev \
      libtinfo-dev \
      sudo \
 && if [ "$TARGETARCH" = "arm64" ]; then \
      GHC_ARCH="aarch64"; \
      CABAL_ARCH="aarch64"; \
      STACK_ARCH="aarch64"; \
    else \
      GHC_ARCH="x86_64"; \
      CABAL_ARCH="x86_64"; \
      STACK_ARCH="x86_64"; \
    fi \
 && curl -fsSL "https://downloads.haskell.org/~ghc/${GHC_VERSION}/ghc-${GHC_VERSION}-${GHC_ARCH}-deb12-linux.tar.xz" -o /tmp/ghc.tar.xz \
 && tar -C /opt -xJf /tmp/ghc.tar.xz \
 && ln -sf /opt/ghc-${GHC_VERSION}-${GHC_ARCH}-* /opt/ghc-current \
 && rm -f /tmp/ghc.tar.xz \
 && curl -fsSL "https://downloads.haskell.org/~cabal/cabal-install-${CABAL_VERSION}/cabal-install-${CABAL_VERSION}-${CABAL_ARCH}-linux-deb12.tar.xz" -o /tmp/cabal.tar.xz \
 && tar -C /usr/local/bin -xJf /tmp/cabal.tar.xz \
 && rm -f /tmp/cabal.tar.xz \
 && curl -fsSL "https://github.com/commercialhaskell/stack/releases/download/v${STACK_VERSION}/stack-${STACK_VERSION}-linux-${STACK_ARCH}.tar.gz" -o /tmp/stack.tar.gz \
 && tar -C /tmp -xzf /tmp/stack.tar.gz \
 && mv /tmp/stack-${STACK_VERSION}-linux-${STACK_ARCH}/stack /usr/local/bin/stack \
 && rm -rf /tmp/stack.tar.gz /tmp/stack-${STACK_VERSION}-linux-${STACK_ARCH} \
 && /opt/ghc-current/bin/ghc --version \
 && cabal --version \
 && stack --version \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/haskell"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Haskell with GHC, cabal, and stack"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="haskell"
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
ENV PATH="/opt/ghc-current/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Size budget
# ---------------------------------------------------------------------------
# COMP_BUDGET=600
# UNCOMP_BUDGET=1800

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
