# Forgejo Actions runner image - java flavour
# Layer count: 3 (base + bu-base + java)
# BU + OpenJDK 21 + Maven
# Package versions pinned per spec

# ---------------------------------------------------------------------------
# Layer 0: Base image pinned by digest
# ---------------------------------------------------------------------------
FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS base

ARG SNAPSHOT_DATE=""

# ---------------------------------------------------------------------------
# Layer 1: BU base packages (shared across all flavours)
# ---------------------------------------------------------------------------
FROM base AS bu-base
RUN if [ -n "$SNAPSHOT_DATE" ]; then \
      sed -i "s|http://archive.ubuntu.com/ubuntu|https://snapshot.ubuntu.com/ubuntu/${SNAPSHOT_DATE}T000000Z|g" /etc/apt/sources.list \
      && sed -i "s|http://security.ubuntu.com/ubuntu|https://snapshot.ubuntu.com/ubuntu/${SNAPSHOT_DATE}T000000Z|g" /etc/apt/sources.list; \
    fi \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      git=1:2.43.0-1ubuntu7.3 \
      git-lfs=3.4.1-1ubuntu0.4 \
      openssh-client=1:9.6p1-3ubuntu13.16 \
      make=4.3-4.1build2 \
      build-essential \
      jq=1.7.1-3ubuntu0.24.04.2 \
      yq=3.1.0-3 \
      curl=8.5.0-2ubuntu10.9 \
      wget=1.21.4-1ubuntu4.1 \
      zip=3.0-13ubuntu0.2 \
      unzip=6.0-28ubuntu4.1 \
      zstd=1.5.5+dfsg2-2build1.1 \
      tar=1.35+dfsg-3build1 \
      gzip=1.12-1ubuntu3.1 \
      ca-certificates=20240203 \
      openssl=3.0.13-0ubuntu3.9 \
      diffutils=1:3.10-1build1 \
      patch=2.7.6-7build3 \
      file=1:5.45-3build1 \
      tree=2.1.1-2ubuntu3.24.04.2 \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/* \
 && find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true \
 && find / -perm -002 -type f -exec chmod o-w {} + 2>/dev/null || true

# ---------------------------------------------------------------------------
# Layer 2: Java-specific additions + user setup (single RUN)
# ---------------------------------------------------------------------------
FROM bu-base AS java

ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-21-jdk-headless \
      maven \
      g++=4:13.2.0-7ubuntu1 \
      libssl-dev=3.0.13-0ubuntu3.9 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/* \
 && userdel -r ubuntu \
 && groupadd -g 1000 runner \
 && useradd -u 1000 -g 1000 -m -s /bin/bash runner \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && chmod 4755 /usr/bin/sudo

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/java"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Java 21 with Maven"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="java"
LABEL runner.base="ubuntu:24.04"
LABEL runner.base.digest="sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54"

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DATE_EPOCH=0
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH:-amd64}
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# ---------------------------------------------------------------------------
# Runtime
# ---------------------------------------------------------------------------
USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
