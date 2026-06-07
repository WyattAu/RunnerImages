# RunnerImages

Deterministic Docker images for Forgejo Actions CI runners. Pinned digests, locked versions, reproducible builds.

## Flavours

| Flavour | Contents | Compressed | Use Case |
|---------|----------|-----------|----------|
| **base-universal** | git, curl, jq, make, gcc, ssh | 190MB | Minimal CI, shell scripts |
| **ubuntu** | base + Docker CLI, sudo, build tools | 202MB | General CI, DinD, builds |
| **python** | base + Python 3.12, pip, venv, dev headers | 204MB | Python CI, ML pipelines |
| **node** | base + Node.js 22, npm, yarn, pnpm | 259MB | JS/TS CI, npm builds |
| **heavy** | base + Node.js + Python + Docker CLI | 282MB | Monorepos, mixed stacks |

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

Need Python / pip / venv?
  -> python

Need Node + Python + Docker?
  -> heavy

Just git + curl + make?
  -> base-universal

Something else?
  -> ubuntu + apt-get install in workflow
```

## Build from Source

```bash
git clone https://github.com/WyattAu/RunnerImages.git
cd RunnerImages
make build                    # build ubuntu (default)
make build FLAVOUR=node       # build a specific flavour
make verify                   # run verification suite
make lint                     # shellcheck + hadolint
```

## Architecture

Every image uses 3 layers for Docker layer deduplication:

```
Layer 0: ubuntu:24.04@sha256:<digest>    (shared, ~78MB)
Layer 1: BU base (git, curl, jq, gcc...) (shared, ~250MB)
Layer 2: flavour-specific packages       (unique per flavour)
```

Docker stores shared layers once. Pulling `ubuntu` then `node` only downloads the unique Layer 2 for node.

## Design Pillars

| Pillar | Description |
|--------|-------------|
| Deterministic | Pinned base digests, pinned package versions, SHA256-verified tarballs |
| Thin | Size budgets enforced at build time, no man pages/docs/static libs |
| Secure | No SUID except sudo, no world-writable files, Trivy scans in CI |
| Compatible | amd64, UID/GID 1000, Docker CLI, standard entrypoint |
| Auditable | OCI labels, versions.lock, SBOM generation planned |
| Maintainable | Renovate for automated updates, shellcheck + hadolint in CI |

## CI/CD

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| Build | push to main (images/scripts) | Build, verify, push all changed flavours |
| Lint | push to main | shellcheck, hadolint, VERSION validation |
| Nightly | daily at 03:00 UTC | Rebuild, Trivy scan, size regression |
| Pages | push to main (docs/) | Deploy landing page |

## Repository Structure

```
images/
  base-universal/   Dockerfile, VERSION, README.md
  ubuntu/           Dockerfile, VERSION, README.md
  node/             Dockerfile, VERSION, README.md
  python/           Dockerfile, VERSION, README.md
  heavy/            Dockerfile, VERSION, README.md
scripts/
  build.sh          Build, push, sign, scan
  verify.sh         40+ verification checks (flavour-aware)
  hooks/            Pre-commit hooks (digest check, version check)
.github/workflows/  CI/CD pipelines
docs/               GitHub Pages landing page
.specs/             Requirements and constraints
```

## License

Apache License 2.0
