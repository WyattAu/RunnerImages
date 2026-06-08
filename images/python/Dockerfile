# Forgejo Actions runner image - python flavour (B1 layered)
# Inherits BU packages from base-universal image
# Adds: Python 3.12 + pip + venv + g++ + dev headers

FROM ghcr.io/wyattau/runner-images/base-universal:1.0.0 AS bu-base

ARG IMAGE_VERSION=dev

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      g++=4:13.2.0-7ubuntu1 \
      python3=3.12.3-0ubuntu2.1 \
      python3-pip=24.0+dfsg-1ubuntu1.3 \
      python3-venv=3.12.3-0ubuntu2.1 \
      python3-dev=3.12.3-0ubuntu2.1 \
      libffi-dev=3.4.6-1build1 \
      libssl-dev=3.0.13-0ubuntu3.9 \
      sudo=1.9.15p5-3ubuntu5.24.04.2 \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* \
 && chmod 4755 /usr/bin/sudo

LABEL org.opencontainers.image.title="runner-images/python"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Python 3.12 with pip, venv, and native extension support"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="python"
LABEL runner.base="base-universal"
LABEL runner.base.tag="1.0.0"

ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV SOURCE_DATE_EPOCH=0
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
