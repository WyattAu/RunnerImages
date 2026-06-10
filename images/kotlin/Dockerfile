# Forgejo Actions runner image - kotlin flavour
# Layer count: 2 (java-base + kotlin)
# Kotlin compiler + Gradle on top of Java 21

# ---------------------------------------------------------------------------
# Layer 0: Base image - Java layer
# ---------------------------------------------------------------------------
FROM ghcr.io/wyattau/runner-images/java:2.0.0 AS java-base

# ---------------------------------------------------------------------------
# Layer 1: Kotlin-specific additions (single RUN)
# ---------------------------------------------------------------------------
FROM java-base AS kotlin

ARG KOTLIN_VERSION=2.1.21
ARG IMAGE_VERSION=dev
ARG TARGETARCH

RUN curl -fsSL "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" -o /tmp/kotlin.zip \
 && unzip /tmp/kotlin.zip -d /usr/local \
 && ln -sf /usr/local/kotlinc/bin/* /usr/local/bin/ \
 && GRADLE_VERSION=8.14.2 \
 && curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
 && unzip /tmp/gradle.zip -d /usr/local \
 && ln -sf /usr/local/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle \
 && apt-get update \
 && apt-get install -y --no-install-recommends sudo \
 && echo 'runner ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/runner \
 && rm -rf /var/lib/apt/lists/* /tmp/kotlin.zip /tmp/gradle.zip \
 && chmod 4755 /usr/bin/sudo \
 && kotlinc -version \
 && gradle --version

# ---------------------------------------------------------------------------
# OCI Labels
# ---------------------------------------------------------------------------
LABEL org.opencontainers.image.title="runner-images/kotlin"
LABEL org.opencontainers.image.description="Forgejo Actions runner image: Kotlin with Gradle"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="$IMAGE_VERSION"
LABEL runner.flavour="kotlin"
LABEL runner.base="java"
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
