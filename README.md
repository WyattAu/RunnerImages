# RunnerImages

Deterministic, multi-arch Docker images for Forgejo Actions CI runners. Pinned digests, locked versions, reproducible builds. Supports **linux/amd64** and **linux/arm64**. 24 flavours.

## Tool Versions

| Flavour | Primary Tool | Version | Other Tools |
|---------|-------------|---------|-------------|
| base-universal | gcc | 14.x | git, curl, jq, make, wget, zip, openssl, ssh |
| c | GCC/G++ | 14.x | cmake, ninja, valgrind, gdb, autoconf, automake |
| deno | Deno | 2.8.x | (multi-arch) |
| ubuntu | docker-ce-cli | 29.5.x | g++, pkg-config, libssl-dev, sudo |
| node | Node.js | 22.22.3 | npm, yarn, pnpm, g++, python3 |
| pnpm | Node.js | 22.22.3 | pnpm, g++, python3 |
| bun | Bun | 1.3.14 | g++, python3 |
| python | Python | 3.12.x | pip, venv, python3-dev, libffi-dev, g++ |
| heavy | Node.js 22 + Python 3.12 | -- | Docker CLI, npm, yarn, pnpm, pip |
| rust | Rust | 1.96.0 | cargo, rustup, g++, libssl-dev |
| rust-full | Rust | 1.96.0 | wasm-pack, cross (amd64), protobuf, cmake |
| ruby | Ruby | 3.4.4 | bundler, gem, libssl-dev, libffi-dev |
| php | PHP | 8.3.x | Composer, curl/mbstring/xml/zip/mysql/pgsql/gd extensions |
| zig | Zig | 0.16.0 | (multi-arch) |
| swift | Swift | 6.1 | SPM (amd64 only) |
| go | Go | 1.26.4 | g++ |
| haskell | GHC | 9.10.x | Cabal, Stack |
| java | OpenJDK | 21.x | Maven, g++ |
| kotlin | Kotlin | 2.1.x | Gradle (layers on java) |
| dotnet | .NET SDK | 8.0.x | g++ |
| elixir | Elixir | 1.18.x | Erlang/OTP, Mix, Hex, Rebar |
| flutter | Flutter | 3.44.1 | Dart, cmake, ninja, clang, GTK/GLU dev |
| nix | Nix | 2.34.x | (amd64 only) |
| r-lang | R | 4.x | devtools, renv, testthat, knitr, rmarkdown |

## Flavours

| Flavour | Contents | Compressed | Use Case |
|---------|----------|-----------|----------|
| **base-universal** | git, curl, jq, make, gcc, ssh | 161MB | Minimal CI, shell scripts |
| **ubuntu** | base + Docker CLI, sudo, build tools | 185MB | General CI, DinD, builds |
| **python** | base + Python 3.12, pip, venv, dev headers | 185MB | Python CI, ML pipelines |
| **bun** | base + Bun 1.3 | 197MB | Bun-first workflows |
| **go** | base + Go 1.26 | 226MB | Go workflows |
| **pnpm** | base + Node.js 22, pnpm (no yarn) | 228MB | Lightweight pnpm-only CI |
| **node** | base + Node.js 22, npm, yarn, pnpm | 231MB | JS/TS CI, npm builds |
| **zig** | base + Zig 0.16 | 246MB | Zig workflows |
| **heavy** | base + Node.js + Python + Docker CLI | 274MB | Monorepos, mixed stacks |
| **nix** | base + Nix package manager (flake-ready) | 281MB | Flake-based builds |
| **java** | base + OpenJDK 21, Maven | 324MB | Java/Kotlin workflows |
| **dotnet** | base + .NET 8.0 SDK | 355MB | C#/.NET workflows |
| **rust** | base + Rust 1.96, cargo, rustup | 450MB | Rust/Cargo workflows |
| **rust-full** | base + Rust + wasm-pack, cross, protobuf, cmake | 490MB | Rust + WASM, full toolchain |
| **flutter** | base + Flutter SDK via git clone | 1579MB | Flutter/Dart, mobile/web |
| **ruby** | base + Ruby 3.4, bundler, gem | pending | Ruby CI, Rails |
| **php** | base + PHP 8.3, Composer | pending | PHP CI, Laravel |
| **swift** | base + Swift 6.1 (amd64 only) | pending | Swift CI, SPM |
| **c** | base + GCC/G++, cmake, ninja, valgrind, gdb | pending | C/C++ CI, systems programming |
| **deno** | base + Deno runtime | pending | Deno-first workflows |
| **elixir** | base + Erlang/OTP + Elixir | pending | Phoenix, Elixir CI |
| **haskell** | base + GHC + Cabal + Stack (amd64 only) | pending | Haskell CI, pure FP |
| **kotlin** | java + Kotlin + Gradle | pending | Kotlin/JVM, KMP |
| **r-lang** | base + R + devtools | pending | Data science, statistics |

## Quick Start

```yaml
# .forgejo/workflows/build.yml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/ubuntu:2
    steps:
      - uses: actions/checkout@v6
      - run: make build
```

## Pull

```bash
# GHCR (default)
docker pull ghcr.io/wyattau/runner-images/ubuntu:2

# Docker Hub (flavour as tag prefix)
docker pull wyattau/runnerimages:ubuntu-2
```

Tags follow semver:
- `2` -- major (latest 2.x.x)
- `2.0` -- minor (latest 2.0.x)
- `2.0.0` -- exact
- `latest` -- most recent

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

Need Ruby / Rails?
  -> ruby

Need PHP / Laravel?
  -> php

Need Zig?
  -> zig

Need Swift?
  -> swift

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

**B1 layered architecture**: `base-universal` is the shared base image. All 23 child flavours inherit from it. The BU layer is built once and shared across all flavours.

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
  ruby/             Dockerfile, VERSION, README.md
  php/              Dockerfile, VERSION, README.md
  zig/              Dockerfile, VERSION, README.md
  swift/            Dockerfile, VERSION, README.md
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
| Docker Hub | `docker.io/wyattau/runnerimages` | Docker Hub token |

### Pull from Different Registries

```bash
# GitHub Container Registry (default)
docker pull ghcr.io/wyattau/runner-images/ubuntu:1

# Docker Hub (flavour as tag prefix)
docker pull wyattau/runnerimages:ubuntu-1
```

## Security

- **Cosign signing**: All images signed with GitHub OIDC (keyless)
- **SBOM generation**: SPDX SBOMs for all flavours
- **Trivy scanning**: Weekly vulnerability and secret scans
- **Pinned digests**: Base image pinned by SHA256
- **Supply chain**: Dependabot + Renovate for dependency updates

## License

Apache License 2.0
