# Universal Properties: Forgejo Actions Runner Images

Properties invariant across **every image** in this repository. If an image lacks any, it is invalid.

---

## UP1: Operating System

| Property | Value |
|----------|-------|
| Distribution | Ubuntu 24.04 LTS (Noble Numbat) |
| Base digest | `sha256:<hex>` (pinned, updated via Renovate) |
| Package manager | `apt` (APT 2.7.x) |
| Shell | `/bin/bash` (bash 5.2+) |
| Init | None (single process) |
| Kernel | Linux (provided by host) |

**Why Ubuntu 24.04:**
- glibc (not musl) — Python native modules work
- `apt-get install` is the most tested CI pattern
- Matches `ubuntu-latest` in GitHub Actions
- Supported until April 2029
- Richest package ecosystem of any Linux distro

## UP2: User

| Property | Value |
|----------|-------|
| Username | `runner` |
| UID | 1000 |
| GID | 1000 |
| Home | `/home/runner` |
| Shell | `/bin/bash` |
| Sudo | Only in flavours that explicitly install it (ubuntu, node, python, heavy) |

**Why UID 1000:** Docker creates the first non-root user as UID 1000. Actions workflows create files as UID 1000. Volumes are owned by UID 1000 on the host.

## UP3: Environment

```dockerfile
ENV HOME=/home/runner
ENV LANG=C.UTF-8
ENV LANGUAGE=C:en
ENV LC_ALL=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/home/runner/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
```

| Variable | Value | Why |
|----------|-------|-----|
| `HOME` | `/home/runner` | `actions/checkout` writes git config here |
| `LANG` | `C.UTF-8` | Locale for string handling |
| `DEBIAN_FRONTEND` | `noninteractive` | Suppresses apt dialogs in CI |
| `PATH` | includes `~/.local/bin` | `pip install --user` installs here |

**Banned:** `PYTHONPATH`, `NODE_PATH`, `GOPATH`, `CARGO_HOME`, `CONDA_DEFAULT_ENV` — use standard paths.

## UP4: BU Base Packages

**Every flavour includes these packages.** This is the BU (Base Universal) layer.

| Category | Packages | Version Pin | Justification |
|----------|----------|-------------|---------------|
| Core | `base-files`, `coreutils`, `bash-completion` | Latest from repo | POSIX environment |
| VCS | `git`, `git-lfs`, `openssh-client` | Pinned per Dockerfile | `actions/checkout`, SSH |
| Build | `make`, `build-essential` | Pinned per Dockerfile | Native modules |
| Data | `jq`, `yq` | Pinned per Dockerfile | JSON/YAML in workflows |
| HTTP | `curl`, `wget` | Pinned per Dockerfile | Downloads, health checks |
| Archive | `zip`, `unzip`, `zstd`, `tar`, `gzip` | Pinned per Dockerfile | Cache, artifacts |
| Crypto | `ca-certificates`, `openssl` | Pinned per Dockerfile | TLS |
| System | `diffutils`, `patch`, `file`, `tree` | Pinned per Dockerfile | Utilities |

**Version pins are examples.** Actual pins are determined at build time and recorded in `versions.lock`.

## UP5: Excluded Packages

| Category | Packages | Why Excluded |
|----------|----------|-------------|
| Daemons | `docker-ce`, `containerd`, `runc`, `systemd`, `dbus` | C6: No Daemons |
| Debug | `strace`, `ltrace`, `valgrind`, `gdb` | Not CI dependencies |
| Editors | `vim`, `nano`, `emacs`, `ed` | Non-interactive |
| Docs | `man-db`, `texinfo` | Never read in CI |
| Servers | `apache2`, `nginx`, `openssh-server` | Security risk |
| Init | `sysvinit`, `upstart` | Not applicable |
| Static libs | `libasan-dev`, `libtsan-dev`, `libubsan-dev` | Never used in CI |
| Locale | `locales` (full) | Only `C.UTF-8` needed |

## UP6: Filesystem

```
/home/runner/              # User home, writable
/home/runner/.local/bin/   # User-installed binaries (pip install --user)
/home/runner/.npm/         # npm cache
/home/runner/.cache/       # General cache
/tmp/                      # Temp directory, writable
/usr/bin/                  # System binaries
/usr/lib/                  # Libraries
/usr/share/                # Shared data
/etc/                      # Configuration
```

**Writable:** `/home/runner/`, `/tmp/`
**Read-only (convention):** Everything else

## UP7: Network

| Property | Value |
|----------|-------|
| DNS | Docker embedded DNS (127.0.0.11) |
| Outbound | Allowed (fetching dependencies) |
| Inbound | None (job containers have no listeners) |
| IPv6 | Disabled (Docker default) |

## UP8: OCI Labels

```dockerfile
LABEL org.opencontainers.image.title="runner-images/<flavour>"
LABEL org.opencontainers.image.description="Forgejo Actions runner image"
LABEL org.opencontainers.image.vendor="WyattAu"
LABEL org.opencontainers.image.source="https://github.com/WyattAu/RunnerImages"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.version="<semver>"
LABEL runner.flavour="<flavour>"
LABEL runner.base="ubuntu:24.04"
LABEL runner.base.digest="sha256:<hex>"
```

## UP9: Reproducibility

Every image must be reproducible:

1. Build 1: `docker build --no-cache -t build1 .`
2. Build 2: `docker build --no-cache -t build2 .`
3. Verify: `docker inspect --format '{{.Id}}' build1` == `docker inspect --format '{{.Id}}' build2`

**Failure to reproduce = build is broken. Do not merge.**

**Current status:** Builds are not yet bit-for-bit identical due to timestamps and apt metadata. The CI reproducibility check logs a WARN (non-blocking). To achieve full reproducibility, add `SOURCE_DATE_EPOCH=0` and pin apt to snapshot mirrors.

## UP10: Verification Checklist

```
[ ] UP1: Based on ubuntu:24.04@sha256:<digest>
[ ] UP2: USER is runner:1000
[ ] UP3: HOME=/home/runner, LANG=C.UTF-8
[ ] UP4: All BU packages present at pinned versions
[ ] UP5: No excluded packages
[ ] UP6: /home/runner/ and /tmp/ writable
[ ] UP7: No hardcoded network config
[ ] UP8: OCI labels present with version and digest
[ ] UP9: Build is reproducible (same SHA256 on rebuild)
[ ] UP10: This checklist passes
```
