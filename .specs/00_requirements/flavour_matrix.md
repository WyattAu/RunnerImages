# Flavour Matrix: Forgejo Actions Runner Images

Flavour definitions with layer architecture, size budgets, verification rules, and usage guidance.

---

## Flavour Taxonomy

Every flavour is a **superset** of the Base Universal (BU) set. Flavours only **add** packages — they never remove BU packages.

```
Base Universal (BU)
  ├── ubuntu       (BU + docker-cli + g++ + pkg-config + sudo)
  ├── node         (BU + node 22 LTS + npm + yarn + pnpm + g++ + python3)
  ├── python       (BU + python 3.12 + pip + venv + g++ + python3-dev + libffi-dev)
  ├── flutter      (BU + flutter + dart + android-sdk) [planned]
  └── heavy        (BU + node + python + docker-cli + g++ + pkg-config + sudo)
```

## Layer Architecture

Every flavour uses a 3-layer build to maximize Docker layer deduplication:

```
Layer 0: ubuntu:24.04@sha256:<digest>
          (Base OS, ~78MB uncompressed)

Layer 1: bu-base (shared across ALL flavours)
          (git, curl, jq, make, gcc, etc., ~250MB uncompressed)

Layer 2: <flavour> (flavour-specific additions only)
          (node/python/docker/flutter, ~100-200MB uncompressed)
```

**Deduplication benefit:** If `ubuntu` and `heavy` share git+curl+gcc from Layer 1, Docker stores Layer 1 once. The unique storage per flavour is only Layer 2.

**Rebuild benefit:** Changing Layer 2 (adding a package) doesn't invalidate Layer 1 cache. Builds are faster.

## Layer Definitions

### Layer 0: Base Image

```dockerfile
FROM ubuntu:24.04@sha256:<DIGEST>
```

| Attribute | Value |
|-----------|-------|
| Source | `ubuntu:24.04` |
| Pin | SHA256 digest |
| Size | ~78MB uncompressed, ~25MB compressed |
| Contents | Ubuntu base OS (apt, dpkg, coreutils, bash, etc.) |

### Layer 1: BU Base

```dockerfile
FROM base AS bu-base
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    # VCS
    git=<ver> \
    git-lfs=<ver> \
    openssh-client=<ver> \
    # Build
    make=<ver> \
    build-essential=<ver> \
    # Data
    jq=<ver> \
    yq=<ver> \
    # HTTP
    curl=<ver> \
    wget=<ver> \
    # Archive
    zip=<ver> \
    unzip=<ver> \
    zstd=<ver> \
    tar=<ver> \
    gzip=<ver> \
    # Crypto
    ca-certificates=<ver> \
    openssl=<ver> \
    # System
    diffutils=<ver> \
    patch=<ver> \
    file=<ver> \
    tree=<ver> \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/* \
  && find /usr/bin -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true \
  && find /usr/lib -name "*.a" -delete 2>/dev/null || true \
  && find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true \
  && find / -perm -002 -type f -exec chmod o-w {} + 2>/dev/null || true
```

| Metric | Value |
|--------|-------|
| Package count | ~18 |
| Compressed | ~100MB |
| Uncompressed | ~250MB |
| Use case | Minimal CI (shell scripts, static analysis) |

### Layer 2: Flavour-Specific

Each flavour adds only its unique packages on top of bu-base:

```dockerfile
FROM bu-base AS ubuntu
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    docker-ce-cli=<ver> \
    g++=<ver> \
    pkg-config=<ver> \
    libssl-dev=<ver> \
    sudo=<ver> \
    iputils-ping=<ver> \
    net-tools=<ver> \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/* \
  && find /usr/bin -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true \
  && find /usr/lib -name "*.a" -delete 2>/dev/null || true \
  && find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true \
  && find / -perm -002 -type f -exec chmod o-w {} + 2>/dev/null || true

# User setup (final stage)
RUN groupadd -g 1000 runner && useradd -u 1000 -g 1000 -m -s /bin/bash runner

ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USER runner
WORKDIR /home/runner
ENTRYPOINT ["/bin/bash"]
```

---

## BU: Base Universal

**The foundation every flavour inherits.** If you only need git, curl, and a shell, this is enough.

| Category | Packages |
|----------|----------|
| VCS | `git`, `git-lfs`, `openssh-client` |
| Build | `make`, `build-essential` (gcc) |
| Data | `jq`, `yq` |
| HTTP | `curl`, `wget` |
| Archive | `zip`, `unzip`, `zstd`, `tar`, `gzip` |
| Crypto | `ca-certificates`, `openssl` |
| System | `diffutils`, `patch`, `file`, `tree` |

| Metric | Value |
|--------|-------|
| Compressed | ~190MB |
| Uncompressed | ~524MB |
| Layer depth | 3 (base + bu-base + user) |
| Use case | Minimal CI (shell scripts, static analysis) |

**Verification rules:**

```bash
# Shell
docker run --rm <image> bash --version
docker run --rm <image> git --version
docker run --rm <image> curl --version
docker run --rm <image> jq --version
docker run --rm <image> make --version

# No docker
docker run --rm <image> docker --version 2>&1 | grep -q "not found"
# No node
docker run --rm <image> node --version 2>&1 | grep -q "not found"
# No python
docker run --rm <image> python3 --version 2>&1 | grep -q "not found"
```

---

## ubuntu: Universal Default

**BU + Docker CLI + build tools + network utilities.** The recommended default for most workflows.

| Category | Additional Packages |
|----------|-------------------|
| Docker | `docker-ce-cli` |
| Build | `g++` (explicit), `pkg-config`, `libssl-dev` |
| System | `sudo`, `iputils-ping`, `net-tools` |

| Metric | Value |
|--------|-------|
| Compressed | ~202MB |
| Uncompressed | ~560MB |
| Layer depth | 3 (base + bu-base + ubuntu) |
| Use case | General CI, Docker-in-Docker, builds |

**When to use:** Default choice. If you're unsure, use this.

**Verification rules:**

```bash
# Docker CLI
docker run --rm <image> docker --version
docker run --rm <image> docker compose version 2>/dev/null || echo "no compose"
# Build tools
docker run --rm <image> g++ --version
docker run --rm <image> pkg-config --version
# Network
docker run --rm <image> ping -c 1 127.0.0.1
```

---

## node: JavaScript/TypeScript Workflows

**BU + Node.js 22 LTS + npm + yarn + pnpm.**

| Category | Additional Packages |
|----------|-------------------|
| Languages | `node` (22.22.3, from tarball), `npm`, `yarn`, `pnpm` |
| Build | `g++` (for native modules), `python3` (for node-gyp) |
| System | `sudo` |

| Metric | Value |
|--------|-------|
| Compressed | ~259MB |
| Uncompressed | ~753MB |
| Layer depth | 3 (base + bu-base + node) |
| Use case | JS/TS CI, npm/yarn/pnpm builds |

**When to use:** Workflow uses `actions/setup-node` or runs `npm install` / `yarn install` / `pnpm install`.

**Verification rules:**

```bash
# Node.js
docker run --rm <image> node --version
docker run --rm <image> npm --version
docker run --rm <image> npx --version
# Package managers
docker run --rm <image> npm install -g yarn && yarn --version
docker run --rm <image> npm install -g pnpm && pnpm --version
# No docker
docker run --rm <image> docker --version 2>&1 | grep -q "not found"
```

---

## python: Python/ML Workflows

**BU + Python 3.12 + pip + venv + build tools for native extensions.**

| Category | Additional Packages |
|----------|-------------------|
| Languages | `python3` (3.12), `python3-pip`, `python3-venv` |
| Build | `g++` (for C extensions), `python3-dev` (headers), `libffi-dev` |
| System | `libssl-dev`, `sudo` |

| Metric | Value |
|--------|-------|
| Compressed | ~204MB |
| Uncompressed | ~561MB |
| Layer depth | 3 (base + bu-base + python) |
| Use case | Python CI, ML pipelines, data science |

**When to use:** Workflow uses `actions/setup-python` or runs `pip install`.

**Verification rules:**

```bash
# Python
docker run --rm <image> python3 --version
docker run --rm <image> pip3 --version
docker run --rm <image> python3 -m venv /tmp/testvenv
# Native extensions
docker run --rm <image> pip3 install --user cffi && python3 -c "import cffi"
# No node
docker run --rm <image> node --version 2>&1 | grep -q "not found"
```

---

## flutter: Mobile/Frontend Workflows [Planned]

**BU + Flutter SDK + Dart + Android SDK.**

| Category | Additional Packages |
|----------|-------------------|
| Languages | `flutter`, `dart` |
| Android | `android-sdk`, `android-sdk-platform-tools`, `cmdline-tools` |
| Build | `g++`, `cmake`, `ninja-build` |
| System | `libgl1-mesa-dev`, `libgtk-3-dev` (Linux desktop) |

| Metric | Value |
|--------|-------|
| Package count | ~60 |
| Compressed | ~800MB |
| Uncompressed | ~2.5GB |
| Layer depth | 3 (base + bu-base + flutter) |
| Use case | Flutter CI, Android builds, Dart packages |

**When to use:** Workflow uses `subosito/flutter-action` or runs `flutter build`.

**Note:** This is a "heavy" flavour. Consider using the `ubuntu` flavour with `flutter install` at runtime if image size matters.

**Verification rules:**

```bash
# Flutter
docker run --rm <image> flutter --version
docker run --rm <image> dart --version
# Android SDK
docker run --rm <image> adb --version
```

---

## heavy: Kitchen Sink

**BU + everything.** For monorepos that need multiple language runtimes.

| Category | Additional Packages |
|----------|-------------------|
| Docker | `docker-ce-cli` |
| Languages | `node` (22.22.3), `npm`, `yarn`, `pnpm`, `python3` (3.12), `python3-pip`, `python3-venv` |
| Build | `g++`, `pkg-config`, `python3-dev`, `libffi-dev`, `libssl-dev` |
| System | `sudo`, `iputils-ping`, `net-tools` |

| Metric | Value |
|--------|-------|
| Compressed | ~282MB |
| Uncompressed | ~818MB |
| Layer depth | 3 (base + bu-base + heavy) |
| Use case | Monorepos, mixed Node+Python, complex CI |

**When to use:** Workflow uses both `actions/setup-node` AND `actions/setup-python`, or you need Docker CLI + multiple languages.

**Verification rules:**

```bash
# All runtimes
docker run --rm <image> node --version
docker run --rm <image> python3 --version
docker run --rm <image> docker --version
# Both package managers
docker run --rm <image> npm --version
docker run --rm <image> pip3 --version
```

---

## Flavour Selection Guide

```
Do you need...
│
├─ Just git + curl + shell?
│  └─ Use: base-universal
│
├─ Docker CLI (for DinD)?
│  └─ Use: ubuntu
│
├─ Node.js / npm / yarn / pnpm?
│  └─ Use: node
│
├─ Python / pip / venv?
│  └─ Use: python
│
├─ Flutter / Dart / Android SDK?
│  └─ Use: flutter
│
├─ Node + Python + Docker?
│  └─ Use: heavy
│
└─ Something else?
   └─ Use: ubuntu + apt-get install in workflow
```

## Forgejo Runner Label Mapping

Each flavour maps to a Forgejo runner label:

| Flavour | Label | daemon.yml entry |
|---------|-------|------------------|
| BU | `base-universal` | `base-universal:docker://ghcr.io/wyattau/runner-images/base-universal:1.0.0` |
| ubuntu | `ubuntu-latest` | `ubuntu-latest:docker://ghcr.io/wyattau/runner-images/ubuntu:1.0.0` |
| node | `node` | `node:docker://ghcr.io/wyattau/runner-images/node:1.0.0` |
| python | `python` | `python:docker://ghcr.io/wyattau/runner-images/python:1.0.0` |
| flutter | `flutter` | `flutter:docker://ghcr.io/wyattau/runner-images/flutter:1.0.0` |
| heavy | `heavy` | `heavy:docker://ghcr.io/wyattau/runner-images/heavy:1.0.0` |

## Package Overlap Matrix

| Package | BU | ubuntu | node | python | flutter | heavy |
|---------|:--:|:------:|:----:|:------:|:-------:|:-----:|
| git | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| curl | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| make | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| gcc/g++ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| jq | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| yq | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| docker-ce-cli | — | ✅ | — | — | — | ✅ |
| nodejs | — | — | ✅ | — | — | ✅ |
| python3 | — | — | ✅* | ✅ | — | ✅ |
| flutter | — | — | — | — | ✅ | — |

*python3 is a dependency of node's build tools in the `node` flavour.

## Future Flavours (Not Yet Defined)

| Flavour | Purpose | Base |
|---------|---------|------|
| `rust` | Rust/Cargo workflows | BU + rustc + cargo |
| `go` | Go workflows | BU + golang |
| `java` | Java/Kotlin workflows | BU + openjdk-21 |
| `dotnet` | .NET workflows | BU + dotnet-sdk-8 |
| `ansible` | Ansible automation | BU + ansible |
| `docker-build` | Docker builds (buildx) | BU + docker-ce-cli + buildx |

---

## Flavour Definition File Format

Each flavour is defined in a TOML file:

```toml
# flavours/ubuntu.toml

[metadata]
name = "ubuntu"
description = "Universal default with Docker CLI and build tools"
base = "ubuntu:24.04"
base_digest = "sha256:<hex>"  # REQUIRED: pinned digest
version = "1.0.0"

[packages]
# BU packages (inherited)
core = ["base-files", "coreutils", "bash-completion"]
vcs = ["git", "git-lfs", "openssh-client", "openssh-keygen"]
build = ["make", "build-essential"]
data = ["jq", "yq"]
http = ["curl", "wget"]
archive = ["zip", "unzip", "zstd", "tar", "gzip"]
crypto = ["ca-certificates", "openssl"]
system = ["diffutils", "patch", "file", "tree"]

# Ubuntu-specific additions
docker = ["docker-ce-cli"]
extra = ["sudo", "iputils-ping", "net-tools"]
build_extra = ["g++", "pkg-config", "libssl-dev"]

[labels]
runner = "ubuntu-latest"
forgejo = "ubuntu-latest:docker://ghcr.io/wyattau/runner-images/ubuntu:1.0.0"

[size_budget]
compressed = 200  # MB
uncompressed = 550  # MB
layers = 3
```

## CI Enforcement Rules

### Per-Flavour Build Checks

```bash
#!/bin/bash
set -euo pipefail

FLAVOUR=$1
IMAGE="ghcr.io/wyattau/runner-images/$FLAVOUR:latest"

# 1. Layer count
LAYERS=$(docker inspect --format '{{len .RootFS.Layers}}' "$IMAGE")
if [ "$LAYERS" -gt 4 ]; then
  echo "FAIL: $FLAVOUR has $LAYERS layers (max 4: base + bu-base + flavour + user)"
  exit 1
fi

# 2. User is 1000:1000
USER_CHECK=$(docker run --rm "$IMAGE" id runner)
echo "$USER_CHECK" | grep -q "uid=1000" || { echo "FAIL: runner UID != 1000"; exit 1; }
echo "$USER_CHECK" | grep -q "gid=1000" || { echo "FAIL: runner GID != 1000"; exit 1; }

# 3. No root processes
docker run --rm "$IMAGE" ps aux | grep -v "PID" | grep -v "ps aux" | grep "root" && {
  echo "FAIL: Found running root processes"
  exit 1
}

# 4. Size budget
source "$(dirname "$0")/sizes.sh"
COMPRESSED=$(docker save "$IMAGE" | gzip -9 | wc -c | awk '{printf "%.0f", $1/1024/1024}')
UNCOMPRESSED=$(docker inspect --format '{{.Size}}' "$IMAGE" | awk '{printf "%.0f", $1/1024/1024}')

BUDGET_COMP=${SIZES[$FLAVOUR]:-225}
BUDGET_UNCOMP=${SIZES_UNCOMP[$FLAVOUR]:-630}

[ "$COMPRESSED" -le "$BUDGET_COMP" ] || { echo "FAIL: compressed ${COMPRESSED}MB > ${BUDGET_COMP}MB"; exit 1; }
[ "$UNCOMPRESSED" -le "$BUDGET_UNCOMP" ] || { echo "FAIL: uncompressed ${UNCOMPRESSED}MB > ${BUDGET_UNCOMP}MB"; exit 1; }

# 5. Flavour-specific verification
bash "$(dirname "$0")/verify-$FLAVOUR.sh" "$IMAGE"
```

### Nightly Cross-Flavour Checks

```bash
#!/bin/bash
set -euo pipefail

FLAVOURS=(base-universal ubuntu node python heavy)

for F in "${FLAVOURS[@]}"; do
  IMAGE="ghcr.io/wyattau/runner-images/$F:latest"

  # Size regression from previous nightly
  PREV=$(gh api repos/wyattau/RunnerImages/actions/artifacts \
    -X GET -F name="$F-size.json" -F per_page=1 \
    | jq -r '.artifacts[0].size_in_bytes // 0')
  CURR=$(docker inspect --format '{{.Size}}' "$IMAGE")

  if [ "$CURR" -gt "$((PREV * 110 / 100))" ] 2>/dev/null; then
    echo "WARN: $F size increased >10% ($PREV → $CURR)"
  fi

  # Reproducibility (build twice, compare)
  DIGEST1=$(docker build -t test1-"$F" "images/$F" -q 2>/dev/null | tail -1)
  DIGEST2=$(docker build -t test2-"$F" "images/$F" -q 2>/dev/null | tail -1)
  if [ "$DIGEST1" != "$DIGEST2" ]; then
    echo "FAIL: $F not reproducible"
    exit 1
  fi
done
```
