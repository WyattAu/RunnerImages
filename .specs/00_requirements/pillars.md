# Pillars: Forgejo Actions Runner Images

The six pillars. Every design decision must satisfy at least one pillar and violate none.

---

## P1: Deterministic

**A build is the same bitstring every time. No variance. No "works on my machine."**

| Property | Requirement | Verification |
|----------|-------------|--------------|
| Base image | Pinned by SHA256 digest, not tag | `FROM ubuntu:24.04@sha256:<hex>` in every Dockerfile |
| Package versions | Pinned to exact version, not `latest` | `apt-get install git=1:2.45.0-1ubuntu2` |
| Build environment | `DOCKER_BUILDKIT=1`, clean layer cache | CI runs `docker build --no-cache` |
| Timestamp | `SOURCE_DATE_EPOCH=0` for reproducible timestamps | Build produces identical content on second run |
| Output | Same image SHA256 on rebuild | CI verifies `sha256(build1) == sha256(build2)` |

**What this bans:**
- `apt-get install git` (unpinned — installs whatever the mirror has)
- `FROM ubuntu:24.04` without digest (tag moves when Ubuntu publishes a new variant)
- `apt-get update` without `--allow-releaseinfo-change` (may change on mirror update)
- Build arg injection that varies between runs

**What this requires:**
- A `versions.lock` file per flavour, recording every installed package at exact version
- CI rebuilds twice and diff-identical the resulting images
- Base image digest updated via automated PR (Renovate) with CI verification

## P2: Thin

**Every byte in the image must earn its place. Nothing decorative. Nothing "just in case."**

### Layer Architecture

Images use **multi-layer** builds with shared base layers across flavours. This is thinner than single-layer because Docker deduplicates shared layers across flavours in the registry.

```
Layer 0: ubuntu:24.04@sha256:<digest>          (~78MB, shared by all flavours)
Layer 1: BU base (git, curl, jq, make, gcc)    (~200MB, shared by all flavours)
Layer 2: flavour-specific additions             (~50-200MB, unique per flavour)
```

When 6 flavours share Layer 0 and Layer 1, the registry stores those layers **once**. Each flavour only adds its unique Layer 2. Total unique storage = 78 + 200 + sum(layer2 sizes), not 6 × (78 + 200 + layer2).

### Size Budgets

| Layer | Compressed Target | Uncompressed Target |
|-------|-------------------|---------------------|
| Layer 0 (ubuntu base) | ~25MB | ~78MB |
| Layer 1 (BU base) | ~165MB | ~446MB |
| Layer 2 (flavour-specific) | ~12-92MB | ~36-294MB |
| **base-universal (total)** | **~190MB** | **~524MB** |
| **ubuntu (total)** | **~202MB** | **~560MB** |
| **python (total)** | **~204MB** | **~561MB** |
| **node (total)** | **~259MB** | **~753MB** |
| **heavy (total)** | **~282MB** | **~818MB** |

### Thinning Protocol

Every image must execute these thinning steps:

```dockerfile
# 1. Remove package manager metadata
RUN rm -rf /var/lib/apt/lists/*

# 2. Remove man pages, docs, locale data
RUN rm -rf /usr/share/man/* /usr/share/doc/* /usr/share/info/*

# 3. Strip debug symbols from binaries
RUN find /usr/bin -type f -executable -exec strip --strip-unneeded {} + 2>/dev/null || true
RUN find /usr/lib -name "*.a" -delete 2>/dev/null || true

# 4. Remove SUID/SGID binaries (not needed in containers)
RUN find / -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true

# 5. Remove unnecessary locale data
RUN locale-gen C.UTF-8 && rm -rf /usr/share/locale/*
```

### What This Bans

| Item | Why banned |
|------|-----------|
| `man` pages | Never read in CI |
| `doc` directories | Never read in CI |
| `*.a` static archives | Never linked in CI |
| `*.h` header files (unless build-essential) | Only needed for compilation |
| SUID/SGID binaries | Container has no `su`; `sudo` is the only exception (re-added with `chmod 4755` in flavours that include it) |
| Debug symbols | Wasted space |
| `info` pages | Never read in CI |
| `/usr/share/locale/*` (except en_US) | CI uses C.UTF-8 |

## P3: Secure

**Minimal attack surface. No unnecessary binaries. No secrets. No privileges.**

### Binary Inventory

Every binary in the image must be justified. The image contains exactly these categories:

| Category | Binaries | Justification |
|----------|----------|---------------|
| Shell | `bash`, `sh`, `su-exec` | Workflow execution |
| VCS | `git`, `git-lfs`, `ssh`, `ssh-keygen` | `actions/checkout`, git over SSH |
| Build | `make`, `gcc`, `g++`, `ar`, `ld` | Native modules |
| Docker | `docker` (CLI only) | DinD workflows |
| Data | `jq`, `yq` | JSON/YAML processing |
| HTTP | `curl`, `wget` | Downloads, health checks |
| Archive | `zip`, `unzip`, `zstd`, `tar`, `gzip` | Cache, artifacts |
| System | `diff`, `patch`, `file`, `tree`, `find`, `xargs` | Utilities |

**Any binary not in this table must be explicitly justified in a PR and approved.**

### Security Properties

| Property | Requirement | Verification |
|----------|-------------|--------------|
| Non-root | `USER runner` (UID 1000) | `docker run <image> id` returns `uid=1000(runner)` |
| No SUID | `find / -perm /6000 -type f` returns empty | CI scan |
| No world-writable | `find / -perm -002 -type f` returns empty | CI scan |
| No secrets | No tokens, keys, passwords, `.env` files | `grep -r "password\|token\|secret\|key" /` in CI |
| No daemons | No dockerd, containerd, systemd, dbus | Package list audit |
| No hardcoded IPs | No `172.16.*`, `192.168.*`, `10.*` | `grep -r "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+" /etc/` |
| No package manager in final layer | `rm -rf /var/lib/apt/lists/*` executed | Layer inspection |

### Supply Chain

| Requirement | Tool | Frequency |
|-------------|------|-----------|
| Image signing | cosign | Every build |
| SBOM | syft (SPDX 2.3) | Every build |
| Vulnerability scan | Trivy (critical/high only) | Every build |
| Base image verification | `cosign verify` against Chainguard/Ubuntu keys | Every build |
| Package signature verification | `apt-get --allow-unauthenticated=false` | Every build |

## P4: Compatible

**The image must work with any standard Forgejo/GitHub Actions workflow unmodified.**

### Compatibility Matrix

| Workflow Feature | Support |
|------------------|---------|
| `actions/checkout` | ✅ git + ssh |
| `actions/setup-node` | ✅ node + npm pre-installed |
| `actions/setup-python` | ✅ python3 + pip pre-installed |
| `actions/cache` | ✅ tar, gzip, zstd |
| `actions/upload-artifact` | ✅ zip, tar |
| `runs-on: ubuntu-latest` | ✅ via label mapping |
| `container:` with custom image | ✅ any flavour |
| `apt-get install` at runtime | ✅ apt + dpkg available |
| `docker build` (DinD) | ✅ docker-ce-cli mounted to host socket |
| `git clone` over HTTPS | ✅ git + ca-certificates |
| `git clone` over SSH | ✅ ssh + ssh-keygen |
| `npm install` (native modules) | ✅ gcc + g++ + python3 (for node-gyp) |
| `pip install` (C extensions) | ✅ gcc + g++ + python3-dev |

### Forbidden Deviations

| Pattern | Why forbidden |
|---------|---------------|
| Alpine-based | musl breaks Python native modules, `apk` confuses workflows |
| Distroless | No shell, no package manager |
| Custom entrypoint | Breaks `actions/run` invocation |
| Custom shell | Breaks `bash -e -o pipefail` |
| Missing `/bin/bash` | Forgejo Actions defaults to bash |
| Non-standard PATH | Breaks `which` lookups |

## P5: Auditable

**Every component, every version, every decision is traceable.**

### Documentation Requirements

| Artifact | Location | Content |
|----------|----------|---------|
| Per-flavour README | `images/<flavour>/README.md` | Contents, size, use case, changelog |
| VERSION file | `images/<flavour>/VERSION` | Semver version string |
| versions.lock | `images/<flavour>/versions.lock` | Every installed package at exact version |
| Dockerfile | `images/<flavour>/Dockerfile` | Complete build recipe |
| SBOM | `images/<flavour>/sbom.spdx.json` | SPDX 2.3 bill of materials |
| Build log | CI artifact | Full `docker build` output |
| Test results | CI artifact | Smoke test + compatibility test results |

### Audit Trail

Every image build must produce:
1. **Build log** — full `docker build` output with `--progress=plain`
2. **Image manifest** — `docker inspect` output (packages, layers, size)
3. **Vulnerability report** — Trivy scan results
4. **SBOM** — complete dependency tree
5. **Reproducibility proof** — second build SHA256 matches first

## P6: Maintainable

**Updates must be automated, tested, and reversible.**

### Update Strategy

| Component | Update Method | Frequency |
|-----------|--------------|-----------|
| Base image | Renovate PR (digest bump) | Weekly |
| Package versions | Renovate PR (version bump) | Weekly |
| Tool versions | Manual PR (major version changes) | On release |
| Security patches | Automated PR (CVE fix) | Within SLA |

### Versioning

| Bump | Trigger | Example |
|------|---------|---------|
| MAJOR | Base image change, breaking tool removal | 1.x → 2.0.0 |
| MINOR | New tool added, major package update | 1.0.x → 1.1.0 |
| PATCH | Security patch, minor package update | 1.1.0 → 1.1.1 |

### Rollback

Every release must be reversible:
- Previous version tag remains in registry
- `latest` can be repointed to previous version
- `docker pull <image>:<previous-version>` works indefinitely

---

## Pillar Priority

When pillars conflict:

1. **P1: Deterministic** — reproducibility is non-negotiable
2. **P3: Secure** — no security compromise for convenience
3. **P4: Compatible** — workflows must not break
4. **P2: Thin** — minimize size after correctness is guaranteed
5. **P5: Auditable** — traceability is required for trust
6. **P6: Maintainable** — updates must be sustainable

**Example:** Including `build-essential` (~200MB) violates P2 (thin) but satisfies P4 (compatible — native modules need gcc) and P5 (auditable — it's a known, tracked package). It wins because compatible > thin.

**Example:** Including `dockerd` violates P2 (thin), P3 (secure — unnecessary daemon), and P4 (compatible — dockerd conflicts with the host socket mount). It loses on three counts. Excluded.
