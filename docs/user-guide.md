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

### Pulling Images

```bash
# Pull specific version
docker pull ghcr.io/wyattau/runner-images/ubuntu:1.1.0

# Pull latest
docker pull ghcr.io/wyattau/runner-images/ubuntu:latest

# Pull for specific architecture
docker pull --platform linux/arm64 ghcr.io/wyattau/runner-images/ubuntu:1.1.0
```

## Flavour Selection

| Need | Use |
|------|-----|
| Docker CLI (DinD) | ubuntu |
| Node.js / npm / yarn / pnpm | node |
| pnpm only (lighter) | pnpm |
| Bun | bun |
| Python / pip / venv | python |
| Node + Python + Docker | heavy |
| Rust / Cargo | rust |
| Rust + WASM + protobuf | rust-full |
| Go | go |
| Java / Kotlin | java |
| .NET / C# | dotnet |
| Flutter / Dart | flutter |
| Nix flakes | nix |
| Just git + curl + make | base-universal |

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
