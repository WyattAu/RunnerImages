# Changelog

All notable changes to RunnerImages are documented here.

## [1.2.0] - 2026-06-07

### Added

- **bun flavour**: BU + Bun 1.3.14 + pnpm. Multi-arch (x64/aarch64). For Bun-first workflows.
- **rust-full flavour**: BU + Rust 1.96 + wasm-pack + cross + protobuf-compiler + sqlx-cli + cmake + libsqlite3-dev. Extended Rust toolchain for WASM and full-stack development.
- **pnpm flavour**: BU + Node.js 22 + pnpm only (no yarn). Lightweight alternative to full node flavour.
- **nix flavour**: BU + Nix package manager (single-user install). For flake-based projects.
- **Multi-arch support**: All flavours now build for linux/amd64 and linux/arm64. CI uses QEMU + Docker Buildx for cross-architecture builds. Multi-arch manifests created with `docker buildx imagetools`.
- **Bit-for-bit reproducibility**: `SNAPSHOT_DATE` build arg pins apt sources to `snapshot.ubuntu.com` for deterministic package metadata. All Dockerfiles support `SNAPSHOT_DATE` via the BU layer.
- **Renovate Go tracking**: Go version ARG in go/Dockerfile now tracked by Renovate with `golang-version` datasource.
- **Per-arch image tags**: Images pushed as `<version>-amd64` and `<version>-arm64`; manifest job creates unified multi-arch tags (`latest`, `<version>`, `<major>`, `<minor>`).

### Changed

- **Node.js Dockerfiles**: Use `TARGETARCH` to select amd64 (x64) or arm64 tarball with per-arch SHA256 verification.
- **Go Dockerfile**: Uses `TARGETARCH` to select amd64 or arm64 tarball with per-arch SHA256 verification.
- **Java Dockerfile**: `JAVA_HOME` dynamically set based on `TARGETARCH` (was hardcoded to `amd64`).
- **build.sh**: Accepts `PLATFORM` env var (default: `linux/amd64`). Pushes per-arch tags only. Supports `SNAPSHOT_DATE` build arg. Added size budgets for bun, rust-full, pnpm, nix.
- **verify.sh**: Accepts `PLATFORM` env var. All `docker run` calls include `--platform` flag. Added capability checks for bun, rust-full, nix.
- **Makefile**: All targets pass `PLATFORM` env var.
- **CI build.yml**: Matrix expanded to include `platform: [linux/amd64, linux/arm64]`. Added QEMU, Buildx, and manifest merge job.
- **CI nightly.yml**: Same multi-arch matrix as build.yml. Added bun, rust-full, pnpm, nix to matrix.
- **Removed strip --strip-unneeded**: This was corrupting arm64 binaries (make, unzip) during QEMU cross-compilation.

## [1.1.0] - 2026-06-07

### Added

- **rust flavour**: BU + Rust 1.96.0 + cargo + rustup + g++ + libssl-dev. RUSTUP_HOME=/usr/local/rustup, CARGO_HOME=/usr/local/cargo.
- **go flavour**: BU + Go 1.26.4 from official tarball (SHA256 verified) + g++ + sudo.
- **java flavour**: BU + OpenJDK 21 (headless) + Maven + g++ + libssl-dev + sudo. JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64.
- **dotnet flavour**: BU + .NET 8.0 SDK + g++ + libssl-dev + pkg-config + sudo.
- **flutter flavour**: BU + Flutter 3.44.1 SDK + Dart + cmake + ninja-build + clang + GTK/GLU dev + sudo. No Android SDK (users add in workflow).
- Nightly pipeline: 10-flavour matrix (was 5).
- Cross-flavour consistency check: Node.js version/SHA, docker-ce-cli version.
- Reproducibility: SOURCE_DATE_EPOCH=0 in all Dockerfiles.
- Cosign keyless signing with GitHub OIDC for all flavours.
- SBOM generation (SPDX) for all flavours.
- SECURITY.md, CONTRIBUTING.md.

## [1.0.0] - 2026-06-07

### Added

- **base-universal flavour**: BU layer only (git, curl, jq, make, gcc, wget, zip, openssl, ssh). No docker, no node, no python, no sudo. 190MB compressed.
- **ubuntu flavour**: BU + Docker CLI 29.5.3 + g++ + pkg-config + libssl-dev + sudo + iputils-ping + net-tools. 202MB compressed.
- **node flavour**: BU + Node.js 22.22.3 LTS + npm + yarn + pnpm + g++ + python3 (node-gyp). 259MB compressed.
- **python flavour**: BU + Python 3.12 + pip + venv + python3-dev + libffi-dev + libssl-dev + g++. 204MB compressed.
- **heavy flavour**: BU + Node.js 22.22.3 + Python 3.12 + Docker CLI 29.5.3 + all build tools. 282MB compressed.
- CI pipeline: Build (5 matrix jobs), Verify (40+ flavour-aware checks), Push to GHCR.
- CI pipeline: Lint (shellcheck, hadolint, VERSION validation, digest check, secret scan).
- CI pipeline: Nightly (Trivy security scan, SARIF upload, size regression check).
- CI pipeline: GitHub Pages deployment for landing page.
- Pre-commit hooks: shellcheck, hadolint, base image digest check, VERSION semver check.
- Makefile: build, verify, lint, clean targets.
- Renovate configuration for automated dependency updates.
- Landing page at https://wyattau.github.io/RunnerImages/
- Per-flavour README documentation.
- Spec documents: constraints, pillars, standards, flavour matrix, universal properties.
- 3-layer architecture for Docker layer deduplication across flavours.
- All packages version-pinned. Base image pinned by SHA256 digest.
- Node.js installed from official tarball with SHA256 verification.
- Thinning protocol: no man pages, no docs, no static libs, no SUID (except sudo), no world-writable files.
- OCI labels on all images.
- runner user (UID/GID 1000) with /bin/bash entrypoint.
