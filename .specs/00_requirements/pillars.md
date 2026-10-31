- `apt-get install git` (unpinned; installs whatever the mirror has)
1. **Build log**; full `docker build` output with `--progress=plain`
2. **Image manifest**; `docker inspect` output (packages, layers, size)
3. **Vulnerability report**; Trivy scan results
4. **SBOM**; complete dependency tree
5. **Reproducibility proof**; second build SHA256 matches first
1. **P1: Deterministic**; reproducibility is non-negotiable
2. **P3: Secure**; no security compromise for convenience
3. **P4: Compatible**; workflows must not break
4. **P2: Thin**; minimize size after correctness is guaranteed
5. **P5: Auditable**; traceability is required for trust
6. **P6: Maintainable**; updates must be sustainable
**Example:** Including `build-essential` (~200MB) violates P2 (thin) but satisfies P4 (compatible; native modules need gcc) and P5 (auditable; it's a known, tracked package). It wins because compatible > thin.
**Example:** Including `dockerd` violates P2 (thin), P3 (secure; unnecessary daemon), and P4 (compatible; dockerd conflicts with the host socket mount). It loses on three counts. Excluded.