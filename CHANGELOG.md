# Changelog

## v2.0.0 (2026-06-11)

### 24 Flavours
base-universal, ubuntu, node, pnpm, bun, python, heavy, rust, rust-full, go, java, dotnet, flutter, nix, ruby, php, zig, swift, deno, elixir, kotlin, c, haskell, r-lang

### Architecture
- B1 layered architecture: base-universal as shared base, all flavours inherit
- Multi-arch support: amd64 + arm64 (except flutter/nix/swift/haskell)
- Independent versioning per flavour
- Multi-registry publishing: GHCR + Docker Hub + optional Quay.io

### CI/CD
- Smart change detection: only builds changed flavours
- Nightly full rebuild with --no-cache + Trivy scanning
- SBOM (SPDX), cosign keyless signing, SLSA v0.2 provenance attestations
- Build retry (2 attempts), Docker Hub publish retry (3 attempts)
- Pre-commit hooks: hadolint, shellcheck, VERSION format, base image digest pinning
- Renovate: auto-merge minor/patch for actions + base image digests
- Dependabot: weekly checks for base image + GitHub Actions

### Supply Chain Security
- SBOM generation (anchore/sbom-action)
- Cosign keyless signing
- In-toto provenance attestations (SLSA v0.2)
- Trivy vulnerability scanning (weekly + nightly)
- Base image digest pinning enforced by pre-commit hook

### Tooling
- scripts/build.sh: configurable --cache/--no-cache, per-flavour size budgets
- scripts/verify.sh: flavour-aware verification, 24 flavour capability map
- scripts/discover-images.sh: smart change detection
- scripts/integration-test.sh: cross-flavour consistency checks
- scripts/check-upstream-versions.sh: upstream version monitoring
- scripts/bump-version.sh: independent version bumping with cascade

## Recent Changes

### Features
- 66e021f feat: in-toto provenance attestations via cosign attest
- 96a6f7b feat: devcontainers, integration tests, Quay.io mirror support

### Bug Fixes
- 1710432 fix: new flavour build failures
- 059d842 fix: update BU consistency checks for unversioned apt packages
- 79d5e75 fix: add published-flavour exemption to CI lint digest check
- cdc2133 fix: shellcheck quote warning in build cache flag

### Other Changes
- d6a5827 chore: bump all actions to latest major versions, Renovate auto-merge, GHC bindist
- 379f68a docs: update changelog [skip ci]
- 0a4285b docs: update changelog [skip ci]
