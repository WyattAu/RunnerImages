| `ubuntu:24.04@sha256:<hex>` | `ubuntu:24.04` (tag without digest; moves) |
**Verification:** `docker inspect --format '{{.Id}}' <image>`; base layer matches expected digest.
**Verification:** `docker run <image> dpkg -l`; every package shows exact version, no `(none)` entries.
| Layer 0 | Base image (`ubuntu:24.04@sha256:<digest>`) | Yes; all flavours |
| Layer 1 | BU base packages (git, curl, jq, make, gcc, etc.) | Yes; all flavours |
| Layer 2 | Flavour-specific packages (node, python, docker-cli, etc.) | No; unique per flavour |
**Why not more than 3 layers:** Each layer adds metadata overhead. The runner image needs all tools at runtime; there's no benefit to splitting Layer 2 further.
**Verification:** `docker run <image> dpkg -l`; none of these packages appear.
# (config contains no keys: keys are injected at runtime)
**Verification:** `docker history <image> --no-trunc`; no secrets in any layer command. `trivy image --scanners secret <image>`; no secrets found.
**Verification:** `docker run <image> env`; no IP addresses. `docker run <image> cat /etc/hosts`; default Docker DNS only.
1. **C7 (No Secrets)**; absolute, immediate rejection
2. **C1 (Base Image)**; absolute, no exceptions
3. **C6 (No Daemons)**; absolute, no exceptions
4. **C2 (User Identity)**; absolute, no exceptions
5. **C3 (Package Pinning)**; absolute, reproducibility depends on it
6. **C4 (Layer Architecture)**; absolute, deduplication depends on it
7. **C5 (Thinning Protocol)**; absolute, size budget depends on it
8. **C9 (Entrypoint)**; absolute, workflow compatibility depends on it
9. **C8 (No Hardcoded Hostnames)**; absolute, portability depends on it
10. **C10 (Single Architecture)**; can be relaxed for ARM support
11. **C11 (No Runtime Install)**; absolute, deterministic builds depend on it
12. **C12 (Size Enforcement)**; absolute, CI gate