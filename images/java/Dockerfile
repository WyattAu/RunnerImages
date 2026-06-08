# Forgejo Actions runner image - java flavour (B1 layered)
# Inherits BU packages from base-universal image
# Adds: OpenJDK 21 + Maven

FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      openjdk-21-jdk-headless \
      maven \
      g++=4:13.2.0-7ubuntu1 \
      libssl-dev=3.0.13-0ubuntu3.9 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

LABEL org.opencontainers.image.title="runner-images/java"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Java 21 with Maven"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="java"
LABEL runner.base="base-universal"
LABEL runner.base.tag="1.0.0"

ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DATE_EPOCH=0
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH:-amd64}
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
