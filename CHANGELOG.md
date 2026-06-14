# Changelog

## Recent Changes

### Features
- 70abe7d feat: track GHC and Gradle in upstream version checker
- 66e021f feat: in-toto provenance attestations via cosign attest
- 96a6f7b feat: devcontainers, integration tests, Quay.io mirror support

### Bug Fixes
- c1c5c4d fix(elixir): compile from source instead of precompiled zip
- 23f8025 fix: haskell ghc/cabal/stack verify use command -v (stderr issue)
- 1f68245 fix: shellcheck quote compatibility for verify checks
- 05e2a3b fix: gradle verify, haskell budget 650, r-lang Rscript, elixir retry loop
- 316ee1e fix: kotlin verify (java/layers/budget), haskell make install, elixir subshell fallback
- 600d6a2 fix: kotlin/r-lang verify stderr, haskell budget+strip, elixir hex.pm mirror
- 17e837b fix: haskell size budget 600->650MB, Rscript verify stderr redirect
- 6a2bed3 fix(ruby): cd / before rm -rf build dir (getcwd ENOENT)
- 19cab9a fix(ruby): source build instead of ruby-builder (wrong shebang paths)
- 3057f9d fix: ruby/haskell PATH approach, kotlin explicit symlinks, r-lang libuv
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
- 454d412 docs: update changelog [skip ci]
- ca1be2a docs: update changelog [skip ci]
- 3063d40 docs: update changelog [skip ci]
- 76154ec docs: update changelog [skip ci]
- 1a465b5 docs: update changelog [skip ci]
- 005acd5 docs: update changelog [skip ci]
- b422a28 docs: update changelog [skip ci]
- b2a056c docs: update changelog [skip ci]
- 0c4b871 revert: remove build concurrency group (caused nightly cancellation)
- da8ef29 docs: update changelog [skip ci]
- c12db40 docs: update changelog [skip ci]
- 0761519 docs: update README sizes from GHCR, version refs v1->v2
- 1bb1e04 chore: bump all actions to latest major versions, Renovate auto-merge, GHC bindist
- 776ea1c docs: update changelog [skip ci]
- d6a5827 chore: bump all actions to latest major versions, Renovate auto-merge, GHC bindist
- 379f68a docs: update changelog [skip ci]
- 0a4285b docs: update changelog [skip ci]

