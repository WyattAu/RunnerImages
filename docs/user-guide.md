# RunnerImages User Guide

## Quick Start

### Using in Forgejo Actions

```yaml
# .forgejo/workflows/build.yml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/ubuntu:1
    steps:
      - uses: actions/checkout@v4
      - run: make build
```

### Using in GitHub Actions

```yaml
# .github/workflows/build.yml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: wyattau/runnerimages:ubuntu-1
    steps:
      - uses: actions/checkout@v4
      - run: make build
```

### Pulling Images

```bash
# Pull specific version from GHCR
docker pull ghcr.io/wyattau/runner-images/ubuntu:1.1.0

# Pull latest from GHCR
docker pull ghcr.io/wyattau/runner-images/ubuntu:latest

# Pull from Docker Hub (flavour as tag prefix)
docker pull wyattau/runnerimages:ubuntu-1
docker pull wyattau/runnerimages:ubuntu-latest

# Pull for specific architecture
docker pull --platform linux/arm64 ghcr.io/wyattau/runner-images/ubuntu:1.1.0
```

## Flavour Selection

| Need | Use | Key Tools |
|------|-----|-----------|
| Docker CLI (DinD) | ubuntu | docker-ce-cli, g++, sudo |
| Node.js / npm / yarn / pnpm | node | Node 22, npm, yarn, pnpm, g++, python3 |
| pnpm only (lighter) | pnpm | Node 22, pnpm, g++, python3 |
| Bun | bun | Bun 1.3, g++, python3 |
| Python / pip / venv | python | Python 3.12, pip, venv, g++ |
| Node + Python + Docker | heavy | Node 22 + Python 3.12 + Docker CLI |
| Rust / Cargo | rust | Rust 1.96, cargo, rustup, g++ |
| Rust + WASM + protobuf | rust-full | Rust 1.96 + wasm-pack + cross + cmake |
| Go | go | Go 1.26, g++ |
| Java / Kotlin | java | OpenJDK 21, Maven, g++ |
| .NET / C# | dotnet | .NET 8.0 SDK, g++ |
| Flutter / Dart | flutter | Flutter 3.44, cmake, ninja, clang |
| Nix flakes | nix | Nix 2.34 (amd64 only) |
| Just git + curl + make | base-universal | git, curl, jq, make, gcc |

## Example Workflows

See `docs/examples/` for complete workflow files:

| Example | Flavour | Description |
|---------|---------|-------------|
| `node-ci.yml` | node | Basic Node.js CI |
| `node-matrix.yml` | node | Multi-version Node.js matrix |
| `python-ci.yml` | python | Python with pip and pytest |
| `go-ci.yml` | go | Go test and build |
| `rust-ci.yml` | rust | Cargo build, test, clippy |
| `rust-full-ci.yml` | rust-full | WASM + cross-compilation |
| `java-ci.yml` | java | Maven test and package |
| `dotnet-ci.yml` | dotnet | dotnet restore, build, test, publish |
| `bun-ci.yml` | bun | Bun install, test, build |
| `pnpm-ci.yml` | pnpm | pnpm frozen-lockfile CI |
| `flutter-ci.yml` | flutter | Flutter analyze and test |
| `nix-ci.yml` | nix | Nix flake check and build |
| `docker-dind.yml` | ubuntu | Docker-in-Docker |
| `heavy-fullstack.yml` | heavy | Node + Python + Docker full-stack |

## Building from Source

```bash
git clone https://github.com/WyattAu/RunnerImages.git
cd RunnerImages

# Build specific flavour
make build FLAVOUR=ubuntu

# Build for arm64
PLATFORM=linux/arm64 make build FLAVOUR=ubuntu

# Build all flavours
make build-all

# Verify image
make verify FLAVOUR=ubuntu

# Run linter
make lint
```

## Architecture

All images use B1 layered architecture:

```
Layer 0: ubuntu:24.04@sha256:<digest>     (shared, ~78MB)
Layer 1: BU base (git, curl, jq, gcc...)  (shared, ~250MB)
Layer 2: flavour-specific packages        (unique per flavour)
```

`base-universal` is built once and shared across all flavours. Docker stores shared layers once.

## Supply Chain Security

All images are:
- Built from pinned base images (SHA256 digest)
- Signed with cosign (keyless, GitHub OIDC)
- Scanned with Trivy (weekly)
- SBOM generated (SPDX format)

## Reproducible Builds

Use `SNAPSHOT_DATE` for deterministic apt package versions:

```bash
SNAPSHOT_DATE=20240101 make build FLAVOUR=ubuntu
```

## Troubleshooting

### Image not found
```bash
# Check if image exists
docker manifest inspect ghcr.io/wyattau/runner-images/ubuntu:1.1.0-amd64
```

### Build fails
```bash
# Check BU consistency
./scripts/check-bu-consistency.sh

# Check cross-flavour consistency
./scripts/check-cross-flavour-consistency.sh
```

### Verification fails
```bash
# Run verification with verbose output
PLATFORM=linux/amd64 ./scripts/verify.sh ubuntu
```
