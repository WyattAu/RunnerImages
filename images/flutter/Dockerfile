# Forgejo Actions runner image - flutter flavour (B1 layered)
# Inherits BU packages from base-universal image
# Adds: Flutter SDK + Dart + build tools

FROM ghcr.io/wyattau/runner-images/base-universal:2.0.0 AS bu-base

ARG FLUTTER_VERSION=3.44.1
ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      cmake \
      ninja-build \
      g++=4:13.2.0-7ubuntu1 \
      pkg-config=1.8.1-2build1 \
      clang \
      libgtk-3-dev \
      libglu1-mesa \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && git clone --depth 1 --branch ${FLUTTER_VERSION} \
      https://github.com/flutter/flutter.git /opt/flutter \
 && git config --global --add safe.directory /opt/flutter \
 && /opt/flutter/bin/flutter config --no-analytics \
 && /opt/flutter/bin/flutter precache \
 && chown -R runner:runner /opt/flutter \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

LABEL org.opencontainers.image.title="runner-images/flutter"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Flutter SDK with Dart and build tools"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="flutter"
LABEL runner.base="base-universal"
LABEL runner.base.tag="2.0.0"

ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DATE_EPOCH=0
ENV PATH="/opt/flutter/bin:/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
