# Changelog

## Recent Changes

### Features
- 70abe7d feat: track GHC and Gradle in upstream version checker
- 66e021f feat: in-toto provenance attestations via cosign attest
- 96a6f7b feat: devcontainers, integration tests, Quay.io mirror support

### Bug Fixes
- 57057b8 fix: ruby explicit bin copy (no glob), haskell bindist via PATH
- 2f2d7a8 fix: ruby/haskell cp -a instead of ln -sf glob, kotlin budget, r-lang deps, elixir retry
- 9cedec6 fix(nightly): YAML expression parsing for Trivy image-ref
- f087b51 fix(nightly): Trivy scan uses per-arch tag, add continue-on-error
- 4a8b36e fix(ruby): symlink ruby binaries to /usr/local/bin
- 1710432 fix: new flavour build failures
- 059d842 fix: update BU consistency checks for unversioned apt packages
- 79d5e75 fix: add published-flavour exemption to CI lint digest check
- cdc2133 fix: shellcheck quote warning in build cache flag

### Other Changes
- 0c4b871 revert: remove build concurrency group (caused nightly cancellation)
- da8ef29 docs: update changelog [skip ci]
- c12db40 docs: update changelog [skip ci]
- 0761519 docs: update README sizes from GHCR, version refs v1->v2
- 1bb1e04 chore: bump all actions to latest major versions, Renovate auto-merge, GHC bindist
- 776ea1c docs: update changelog [skip ci]
- d6a5827 chore: bump all actions to latest major versions, Renovate auto-merge, GHC bindist
- 379f68a docs: update changelog [skip ci]
- 0a4285b docs: update changelog [skip ci]

