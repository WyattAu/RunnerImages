# RunnerImages

Deterministic, minimal Docker images for Forgejo Actions CI runners.

## Flavours

| Flavour | Base | Status | Description |
|---------|------|--------|-------------|
| ubuntu | ubuntu:24.04 | Available | Docker CLI, Node.js 22, build tools |
| node | ubuntu:24.04 | Planned | Node.js-focused with pnpm, yarn |
| python | ubuntu:24.04 | Planned | Python toolchain, virtualenv |
| heavy | ubuntu:24.04 | Planned | Full SDK: .NET, Java, Go, Rust |
| flutter | ubuntu:24.04 | Planned | Flutter + Android SDK |

All images are published to `ghcr.io/wyattau/runner-images`.

## Quick Start

Use the ubuntu image in a Forgejo Actions workflow:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/ubuntu:1
    steps:
      - uses: actions/checkout@v4
      - run: node --version
      - run: docker --version
      - run: make build
```

Tags follow semver: `1` (major), `1.0` (minor), `1.0.0` (exact), `latest`.

## Build

Using Makefile:

```bash
make build                          # build ubuntu (default)
make build FLAVOUR=ubuntu           # explicit flavour
make build-push                     # build and push to registry
make build-scan                     # build and run Trivy security scan
make build-all                      # build all flavours
```

Using scripts directly:

```bash
./scripts/build.sh ubuntu           # build only
./scripts/build.sh ubuntu --push    # build and push
./scripts/build.sh ubuntu --scan    # build and scan with Trivy
./scripts/build.sh ubuntu --sign    # sign with cosign
./scripts/build.sh ubuntu --sbom    # generate SBOM with syft
```

The registry defaults to `ghcr.io/wyattau/runner-images`. Override with `REPO`.

## Verify

After building, run the verification suite:

```bash
make verify                         # verify ubuntu image
make verify FLAVOUR=ubuntu          # explicit flavour
make verify-all                     # verify all built images
```

The verification script (`scripts/verify.sh`) checks:

- User identity (UID/GID 1000, HOME, whoami)
- Environment variables (LANG, LC_ALL, DEBIAN_FRONTEND, PATH)
- Tool availability (git, ssh, make, gcc, g++, jq, yq, curl, wget, zip, unzip, zstd, tar, gzip, openssl, diff, patch, file, tree, docker, node, npm, pkg-config, sudo)
- Runtime functionality (apt-get update, package install)
- Entrypoint is `/bin/bash`
- Architecture is `amd64`
- OCI labels present
- Security (no unexpected SUID binaries, no world-writable files)
- Layer count <= 4
- Size within budget

## Architecture

Images follow a 3-layer design enforced by multi-stage builds:

```
Layer 0: base       ubuntu:24.04 pinned by SHA256 digest
Layer 1: bu-base    Shared build utilities (git, curl, jq, etc.)
Layer 2: <flavour>  Flavour-specific packages + user setup
```

Key constraints:

- **Base image pinning**: `FROM ubuntu:24.04@sha256:<digest>` -- the digest is verified at build time, preventing supply-chain drift.
- **Version pinning**: All apt packages pinned to exact versions (e.g., `git=1:2.43.0-1ubuntu7.3`). Node.js tarball verified by SHA256 checksum.
- **Max 4 filesystem layers**: Enforced by the verify script. The 4th layer is the Docker metadata layer.
- **Single non-root user**: `runner` (UID/GID 1000) with passwordless sudo.

### Ubuntu Image Contents

**Layer 1 (bu-base)**: git, git-lfs, openssh-client, make, build-essential, jq, yq, curl, wget, zip, unzip, zstd, tar, gzip, ca-certificates, openssl, diffutils, patch, file, tree.

**Layer 2 (ubuntu)**: docker-ce-cli, g++, pkg-config, libssl-dev, Node.js 22 (official tarball with SHA256 verification), sudo, iputils-ping, net-tools.

Post-install hardening per layer: strip binaries, remove static archives (`.a`), clear SUID/SGID bits, remove world-writable permissions, purge man/doc/info pages.

## The Six Pillars

| Pillar | Principle |
|--------|-----------|
| Deterministic | Pinned base digests, pinned package versions, SHA256-verified tarballs. Reproducible from spec. |
| Thin | Compressed budget enforced at build time. No man pages, docs, static libs, or caches. |
| Secure | No SUID except sudo, no world-writable files, no secrets in image, Trivy scans in CI. |
| Compatible | amd64 architecture, standard UID/GID 1000, Docker CLI for sibling containers. |
| Auditable | OCI labels, versions.lock generated per build, SBOM generation with syft, cosign signing. |
| Maintainable | Renovate for automated updates, shellcheck + hadolint in CI, pre-commit hooks, single-command build. |

## Size Budgets

| Flavour | Compressed | Uncompressed | Max Layers |
|---------|-----------|-------------|------------|
| ubuntu | <= 225 MB | <= 630 MB | 4 |
| node | <= 225 MB | <= 630 MB | 4 |
| python | <= 225 MB | <= 630 MB | 4 |
| heavy | <= 350 MB | <= 900 MB | 4 |
| flutter | <= 350 MB | <= 900 MB | 4 |

Size checks are enforced at build time and during verification. Builds fail if budgets are exceeded.

## CI/CD Pipelines

### Build (`build.yml`)

Triggers on push/PR to `main` when `images/**` or `scripts/**` change. Detects changed flavours, builds and verifies each, pushes to GHCR on merge to main, and generates `versions.lock`.

### Nightly (`nightly.yml`)

Runs daily at 03:00 UTC. Rebuilds all flavours, verifies, runs Trivy vulnerability and secret scans (SARIF uploaded to CodeQL), pushes rebuilt images, and checks for >10% size regression.

### Lint (`lint.yml`)

Runs on every push/PR to `main`. Enforces: shellcheck on all shell scripts, semver validation on VERSION files, base image digest pinning, no secrets in Dockerfiles, no banned packages (docker daemon, systemd, ssh-server, etc.).

### Pre-commit Hooks

Install with `pre-commit install`. Enforces: shellcheck, hadolint, base image digest pinning, VERSION semver format, trailing whitespace, end-of-file fixer, no direct commits to main.

### Renovate

Configured in `renovate.json`. Runs on weekends. Manages: base image digest updates, Node.js version bumps, GitHub Actions versions. Rate-limited to 3 concurrent PRs, 1 per hour.

## Contributing

1. Create a feature branch from `main` (direct commits to `main` are blocked by pre-commit).
2. Make changes. Follow existing conventions:
   - Pin all package versions in Dockerfiles.
   - Pin base images by SHA256 digest.
   - Keep layer count within budget.
   - Run `make lint` and `make verify` before pushing.
3. Open a pull request. CI will run lint, build, and verify.
4. Ensure all checks pass before requesting review.

## License

Apache License 2.0. See [LICENSE](LICENSE).
