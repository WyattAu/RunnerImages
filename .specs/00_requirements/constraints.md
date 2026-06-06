# Constraints: Forgejo Actions Runner Images

Hard constraints. No image may violate these. Each constraint has a verification method.

---

## C1: Base Image

**Every image MUST be based on `ubuntu:24.04` pinned by SHA256 digest.**

```dockerfile
FROM ubuntu:24.04@sha256:8a338e58a6e95e3f3a430e48d48f6f31b93e2e5c4e8c0e5c8e8e8e8e8e8e8e8e
```

| Allowed | Banned |
|---------|--------|
| `ubuntu:24.04@sha256:<hex>` | `ubuntu:24.04` (tag without digest — moves) |
| `ubuntu:24.04` (for local dev only) | `ubuntu:latest`, `ubuntu:jammy`, `ubuntu:noble` |
| `debian:bookworm-slim` (as alternative) | `alpine:*`, `scratch`, `wolfi-base`, `cgr.dev/*` |

**Verification:** `docker inspect --format '{{.Id}}' <image>` — base layer matches expected digest.

**Update mechanism:** Renovate creates PR to bump digest. CI rebuilds twice, verifies reproducibility, merges if identical.

## C2: User Identity

**Every image MUST run as UID 1000 (runner).**

```dockerfile
RUN groupadd -g 1000 runner && \
    useradd -u 1000 -g 1000 -m -s /bin/bash runner
```

| Property | Value | Verification |
|----------|-------|--------------|
| UID | 1000 | `docker run <image> id -u` → `1000` |
| GID | 1000 | `docker run <image> id -g` → `1000` |
| Username | `runner` | `docker run <image> id -un` → `runner` |
| Home | `/home/runner` | `docker run <image> echo $HOME` → `/home/runner` |
| Shell | `/bin/bash` | `docker run <image> getent passwd runner` → `bash` |

**Banned:** UID 0 (root), UID 65532 (wolfi), UIDs > 10000 (non-standard).

## C3: Package Version Pinning

**Every package MUST be pinned to an exact version.**

```dockerfile
# Correct
RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.45.0-1ubuntu2 \
    curl=8.5.0-2ubuntu10.4 \
    jq=1.7-1 \
  && rm -rf /var/lib/apt/lists/*

# Wrong
RUN apt-get update && apt-get install -y git curl jq
```

**Verification:** `docker run <image> dpkg -l` — every package shows exact version, no `(none)` entries.

**Version resolution:** `apt-cache policy <package>` on the pinned base image to determine available versions. Record in `versions.lock`.

**Exception:** `build-essential` is a metapackage that cannot be version-pinned. It is pinned transitively via its dependencies.

## C4: Layer Architecture

**Every image MUST use exactly 3 layers.**

| Layer | Content | Shared? |
|-------|---------|---------|
| Layer 0 | Base image (`ubuntu:24.04@sha256:<digest>`) | Yes — all flavours |
| Layer 1 | BU base packages (git, curl, jq, make, gcc, etc.) | Yes — all flavours |
| Layer 2 | Flavour-specific packages (node, python, docker-cli, etc.) | No — unique per flavour |

**Why not single-layer:** Docker deduplicates shared layers. With 6 flavours sharing Layer 0 + Layer 1, the registry stores 2 layers + 6 unique Layer 2s. A single-layer approach stores 6 full copies.

**Why not more than 3 layers:** Each layer adds metadata overhead. The runner image needs all tools at runtime — there's no benefit to splitting Layer 2 further.

**Verification:** `docker history <image>` shows exactly 3 entries (plus the base image).

## C5: Thinning Protocol

**Every image MUST execute these thinning steps in Layer 1 and Layer 2.**

```dockerfile
# In every RUN that installs packages:
RUN apt-get update && apt-get install -y --no-install-recommends \
    <packages> \
  && rm -rf /var/lib/apt/lists/* \
  && rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/* \
  && find /usr/bin -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true \
  && find /usr/lib -name "*.a" -delete 2>/dev/null || true \
  && find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true \
  && find / -perm -002 -type f -exec chmod o-w {} + 2>/dev/null || true
```

| Step | What it removes | Size saved |
|------|----------------|-----------|
| `rm -rf /var/lib/apt/lists/*` | Package manager metadata | ~5-10MB |
| `rm -rf /usr/share/man/*` | Man pages | ~15-20MB |
| `rm -rf /usr/share/doc/*` | Documentation | ~10-15MB |
| `rm -rf /usr/share/info/*` | Info pages | ~2-5MB |
| `strip --strip-unneeded` | Debug symbols from binaries | ~20-50MB |
| `find *.a -delete` | Static archives | ~30-80MB |
| `chmod a-s` | SUID/SGID bits | 0 bytes (security) |
| `chmod o-w` | World-writable files | 0 bytes (security) |

**Verification:** `docker run <image> find / -perm /6000 -type f` → empty. `docker run <image> find / -name "*.a"` → empty.

## C6: No Daemons

**No background services. No init systems. No process managers.**

| Banned Package | Why |
|----------------|-----|
| `docker-ce` (daemon) | Conflicts with host socket mount |
| `containerd` | Docker daemon dependency |
| `runc` | Container runtime |
| `systemd`, `systemd-sysv` | Init system |
| `dbus`, `dbus-x11` | IPC system |
| `cron`, `at` | Job schedulers |
| `supervisord`, `pm2` | Process managers |
| `openssh-server` | SSH daemon (client only) |

**Verification:** `docker run <image> dpkg -l` — none of these packages appear.

## C7: No Secrets

**No credentials, tokens, keys, or passwords in any layer.**

```dockerfile
# BANNED
ENV API_TOKEN=xxx
COPY .env /app/.env
COPY id_rsa /home/runner/.ssh/
RUN echo "password" > /etc/secret

# ALLOWED
COPY --chown=runner:runner .ssh/config /home/runner/.ssh/config
# (config contains no keys — keys are injected at runtime)
```

**Verification:** `docker history <image> --no-trunc` — no secrets in any layer command. `trivy image --scanners secret <image>` — no secrets found.

## C8: No Hardcoded Hostnames

**Images MUST NOT reference specific hosts, IPs, or URLs (except package repositories).**

| Banned | Allowed |
|--------|---------|
| `ENV DB_HOST=172.16.0.5` | `apt-get install from archive.ubuntu.com` |
| `COPY /etc/hosts` | `curl https://github.com/...` (tool download) |
| `git.wyattau.com` | `packages.ubuntu.com` |
| `ghcr.io/wyattau/*` | `security.ubuntu.com` |

**Verification:** `docker run <image> env` — no IP addresses. `docker run <image> cat /etc/hosts` — default Docker DNS only.

## C9: Entrypoint

**The entrypoint MUST be `/bin/bash`.**

```dockerfile
ENTRYPOINT ["/bin/bash"]
```

Forgejo Actions invokes steps via `bash -c "..."`. The entrypoint must match.

**Banned:** `sh`, `/bin/sh`, `dumb-init`, `tini`, custom scripts, no entrypoint.

**Verification:** `docker inspect --format '{{.Config.Entrypoint}}' <image>` → `[/bin/bash]`

## C10: Single Architecture

**Every image MUST be built for `linux/amd64` only.**

| Required | Optional |
|----------|----------|
| `linux/amd64` | `linux/arm64` (future) |

**Verification:** `docker inspect --format '{{.Architecture}}' <image>` → `amd64`

## C11: No Runtime Package Installation in Dockerfile

**The Dockerfile MUST NOT use `apt-get install` in a way that leaves packages for runtime.**

This means:
- `apt-get install` happens during build, not at container start
- No `entrypoint.sh` that runs `apt-get update && apt-get install`
- No deferred package installation

**Exception:** Workflows may run `apt-get install` at runtime. The image must support this (apt + dpkg available), but the Dockerfile itself must not rely on it.

## C12: Size Enforcement

**CI MUST fail if any image exceeds its size budget.**

| Budget | Compressed | Uncompressed |
|--------|-----------|--------------|
| BU base (Layer 0 + 1) | ≤ 125MB | ≤ 328MB |
| Standard flavour (total) | ≤ 225MB | ≤ 630MB |
| Heavy flavour (total) | ≤ 350MB | ≤ 900MB |

**Measurement:** `docker save <image> | gzip | wc -c` for compressed. `docker inspect --format '{{.Size}}' <image>` for uncompressed.

**Enforcement:** CI script compares actual size to budget. Fails with error if exceeded.

---

## Constraint Priority

1. **C7 (No Secrets)** — absolute, immediate rejection
2. **C1 (Base Image)** — absolute, no exceptions
3. **C6 (No Daemons)** — absolute, no exceptions
4. **C2 (User Identity)** — absolute, no exceptions
5. **C3 (Package Pinning)** — absolute, reproducibility depends on it
6. **C4 (Layer Architecture)** — absolute, deduplication depends on it
7. **C5 (Thinning Protocol)** — absolute, size budget depends on it
8. **C9 (Entrypoint)** — absolute, workflow compatibility depends on it
9. **C8 (No Hardcoded Hostnames)** — absolute, portability depends on it
10. **C10 (Single Architecture)** — can be relaxed for ARM support
11. **C11 (No Runtime Install)** — absolute, deterministic builds depend on it
12. **C12 (Size Enforcement)** — absolute, CI gate
