# Forgejo Actions runner image - elixir flavour
# Layer count: 2 (bu-base + elixir)
# BU packages from base-universal, Erlang/OTP + Elixir + hex + rebar

# ---------------------------------------------------------------------------
# Layer 0: Base image - BU layer from base-universal
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

# ---------------------------------------------------------------------------
# Layer 1: Elixir-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS elixir

ARG ELIXIR_VERSION=1.18.4
ARG ERLANG_VERSION=27
ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      gnupg \
      curl \
      unzip \
      sudo \
 && curl -fsSL https://packages.erlang-solutions.com/erlang_solutions.asc | gpg --dearmor -o /usr/share/keyrings/erlang-solutions.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/erlang-solutions.gpg] https://packages.erlang-solutions.com/debian $(. /etc/os-release && echo "$VERSION_CODENAME") contrib" > /etc/apt/sources.list.d/erlang-solutions.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      esl-erlang \
 && curl -fsSL -o /tmp/elixir.zip "https://github.com/elixir-lang/elixir/releases/download/v${ELIXIR_VERSION}/elixir-otp-${ERLANG_VERSION}.zip" \
 && unzip /tmp/elixir.zip -d /usr/local \
 && rm -f /tmp/elixir.zip \
 && mix local.hex --force \
 && mix local.rebar --force \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo \
 && elixir --version \
 && mix --version

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/elixir"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Elixir with Erlang/OTP, hex, and rebar"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="elixir"
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
