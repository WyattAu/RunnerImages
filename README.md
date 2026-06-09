# RunnerImages

Deterministic, multi-arch Docker images for Forgejo Actions CI runners. Pinned digests, locked versions, reproducible builds. Supports **linux/amd64** and **linux/arm64**.

## Flavours

| Flavour | Contents | Compressed | Use Case |
|---------|----------|-----------|----------|
| **base-universal** | git, curl, jq, make, gcc, ssh | 190MB | Minimal CI, shell scripts |
| **ubuntu** | base + Docker CLI, sudo, build tools | 202MB | General CI, DinD, builds |
| **python** | base + Python 3.12, pip, venv, dev headers | 204MB | Python CI, ML pipelines |
| **node** | base + Node.js 22, npm, yarn, pnpm | 259MB | JS/TS CI, npm builds |
| **pnpm** | base + Node.js 22, pnpm (no yarn) | TBD | Lightweight pnpm-only CI |
| **bun** | base + Bun 1.3 | TBD | Bun-first workflows (bun IS the package manager) |
| **heavy** | base + Node.js + Python + Docker CLI | 282MB | Monorepos, mixed stacks |
| **rust** | base + Rust 1.96, cargo, rustup | 471MB | Rust/Cargo workflows |
| **rust-full** | base + Rust + wasm-pack, cross (amd64 only), protobuf, cmake | TBD | Rust + WASM, full toolchain |
| **go** | base + Go 1.26 | 255MB | Go workflows |
| **java** | base + OpenJDK 21, Maven | 355MB | Java/Kotlin workflows |
| **dotnet** | base + .NET 8.0 SDK | 376MB | C#/.NET workflows |
| **flutter** | base + Flutter SDK via git clone | 2001MB | Flutter/Dart, mobile/web |
| **nix** | base + Nix package manager (single-user, flake-ready) | TBD | Flake-based builds |

## Quick Start

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

## Pull

```bash
docker pull ghcr.io/wyattau/runner-images/ubuntu:1

# Tags follow semver:
#   1         -- major (latest 1.x.x)
#   1.0       -- minor (latest 1.0.x)
#   1.0.0     -- exact
#   latest    -- most recent
```

## Flavour Selection

```
Need Docker CLI (DinD)?
  -> ubuntu

Need Node.js / npm / yarn / pnpm?
  -> node

Need pnpm only (no yarn, lighter)?
  -> pnpm

Need Bun (bun IS the package manager)?
  -> bun

Need Python / pip / venv?
  -> python

Need Node + Python + Docker?
  -> heavy

Need Rust / Cargo?
  -> rust

Need Rust + WASM + protobuf + sqlx?
  -> rust-full

Need Go?
  -> go

Need Java / Kotlin?
  -> java

Need .NET / C#?
  -> dotnet

Need Flutter / Dart?
  -> flutter

Need Nix flakes?
  -> nix

Just git + curl + make?
  -> base-universal

Something else?
  -> ubuntu + apt-get install in workflow
```

## Build from Source

```bash
git clone https://github.com/WyattAu/RunnerImages.git
cd RunnerImages
make build                    # build ubuntu (default, amd64)
make build FLAVOUR=node       # build a specific flavour
PLATFORM=linux/arm64 make build  # build for arm64
make verify                   # run verification suite
make lint                     # shellcheck + hadolint
```

## Architecture

**B1 layered architecture**: `base-universal` is the shared base image. All 13 child flavours inherit from it. The BU layer is built once and shared across all flavours.

```
Layer 0: ubuntu:24.04@sha256:<digest>    (shared, ~78MB)
Layer 1: base-universal (git, curl, jq, gcc...) (shared, ~250MB)
Layer 2: flavour-specific packages       (unique per flavour)
```

Docker stores shared layers once. Pulling `ubuntu` then `node` only downloads the unique Layer 2 for node.

## Design Pillars

| Pillar | Description |
|--------|-------------|
| Deterministic | Pinned base digests, pinned package versions, SHA256-verified tarballs, apt snapshot mirrors for reproducibility |
| Thin | Size budgets enforced at build time, no man pages/docs/static libs |
| Secure | No SUID except sudo, no world-writable files, Trivy scans in CI |
| Multi-arch | linux/amd64 + linux/arm64 with per-arch SHA256 verification |
| Auditable | OCI labels, versions.lock, SBOM (SPDX), cosign signing |
| Maintainable | Renovate for automated updates, shellcheck + hadolint in CI |

## CI/CD

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| Build | push to main (images/scripts/workflows) | 4 jobs: **build-base** (base-universal first), **build** (all child flavours), **manifest-base** (multi-arch for base-universal), **manifest** (multi-arch for all child flavours). Verify, push, SBOM, cosign sign. |
| Lint | push to main | shellcheck, hadolint, VERSION validation |
| Nightly | daily at 03:00 UTC | Rebuild (amd64+arm64), Trivy scan, size regression |
| Pages | push to main (docs/) | Deploy landing page |

## Repository Structure

```
images/
  base-universal/   Dockerfile, VERSION, README.md
  ubuntu/           Dockerfile, VERSION, README.md
  node/             Dockerfile, VERSION, README.md
  pnpm/             Dockerfile, VERSION, README.md
  bun/              Dockerfile, VERSION, README.md
  python/           Dockerfile, VERSION, README.md
  heavy/            Dockerfile, VERSION, README.md
  rust/             Dockerfile, VERSION, README.md
  rust-full/        Dockerfile, VERSION, README.md
  go/               Dockerfile, VERSION, README.md
  java/             Dockerfile, VERSION, README.md
  dotnet/           Dockerfile, VERSION, README.md
  flutter/          Dockerfile, VERSION, README.md
  nix/              Dockerfile, VERSION, README.md
scripts/
  build.sh          Build, push, sign, scan
  verify.sh         40+ verification checks (flavour-aware)
  hooks/            Pre-commit hooks (digest check, version check)
.github/workflows/  CI/CD pipelines (build, lint, nightly, pages)
docs/               GitHub Pages landing page
.specs/             Requirements and constraints
```

## Multi-Cloud Publishing

Images are published to multiple registries:

| Registry | URL | Authentication |
|----------|-----|----------------|
| GHCR | `ghcr.io/wyattau/runner-images/` | GitHub token (automatic) |
| ECR | `public.ecr.aws/wyattau/runner-images/` | AWS IAM role |
| Docker Hub | `docker.io/wyattau/runner-images/` | Docker Hub token |

### Pull from Different Registries

```bash
# GitHub Container Registry (default)
docker pull ghcr.io/wyattau/runner-images/ubuntu:1

# AWS ECR Public
docker pull public.ecr.aws/wyattau/runner-images/ubuntu:1

# Docker Hub
docker pull wyattau/runner-images/ubuntu:1
```

## Security

- **Cosign signing**: All images signed with GitHub OIDC (keyless)
- **SBOM generation**: SPDX SBOMs for all flavours
- **Trivy scanning**: Weekly vulnerability and secret scans
- **Pinned digests**: Base image pinned by SHA256
- **Supply chain**: Dependabot + Renovate for dependency updates

## License

Apache License 2.0
