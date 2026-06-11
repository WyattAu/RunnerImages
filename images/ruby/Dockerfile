# Forgejo Actions runner image - ruby flavour
# Layer count: 2 (bu-base + ruby)
# BU packages from base-universal, Ruby 3.4 + bundler (source build)

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Ruby-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS ruby

ARG RUBY_VERSION=3.4.4
ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libssl-dev \
      libffi-dev \
      libyaml-dev \
      zlib1g-dev \
      libreadline-dev \
      sudo \
 && RUBY_MAJOR=$(echo "$RUBY_VERSION" | cut -d. -f1,2) \
 && if [ "$TARGETARCH" = "arm64" ]; then \
      RUBY_ARCH=aarch64; \
    else \
      RUBY_ARCH=x86_64; \
    fi \
 && curl -fsSL "https://cache.ruby-lang.org/pub/ruby/${RUBY_MAJOR}/ruby-${RUBY_VERSION}.tar.gz" -o /tmp/ruby.tar.gz \
 && tar -xzf /tmp/ruby.tar.gz -C /tmp \
 && cd /tmp/ruby-${RUBY_VERSION} \
 && ./configure --prefix=/usr/local --disable-install-doc \
 && make -j$(nproc) \
 && make install \
 && rm -rf /tmp/ruby.tar.gz /tmp/ruby-${RUBY_VERSION} \
 && gem install bundler --no-document \
 && ruby --version \
 && gem --version \
 && bundler --version \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/ruby"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Ruby with bundler (source build)"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="ruby"
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
