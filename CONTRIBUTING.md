# Contributing to RunnerImages

## Quick Start

```bash
# Build a flavour locally
make build FLAVOUR=ubuntu

# Verify it passes all checks
make verify FLAVOUR=ubuntu

# Run lint
make lint
```

## Repository Structure

```
images/
  base-universal/    Dockerfile, VERSION, README.md
  ubuntu/            Dockerfile, VERSION, README.md
  node/              Dockerfile, VERSION, README.md
  python/            Dockerfile, VERSION, README.md
  heavy/             Dockerfile, VERSION, README.md
  shared/            bu.fragment (canonical BU layer definition)
scripts/
  build.sh           Build, push, sign, scan
  verify.sh          50+ verification checks (flavour-aware)
  check-bu-consistency.sh  Detects BU layer divergence across flavours
specs/
  00_requirements/   Design specs (pillars, standards, constraints, flavour matrix)
```

## Making Changes

### Adding a package to a flavour

1. Edit the flavour's Dockerfile
2. Pin the version: `package=1.2.3-1ubuntu1`
3. Add verification check in `scripts/verify.sh` if needed
4. Update the flavour's README.md
5. Run `make build FLAVOUR=<name> && make verify FLAVOUR=<name>`
6. Check size is within budget
7. Commit with `feat(<flavour>): add <package>`

### Adding a new flavour

1. Create `images/<flavour>/` with Dockerfile, VERSION, README.md
2. Copy BU block from `images/shared/bu.fragment` (must be identical)
3. Add flavour to verify.sh capability map
4. Add size budget to verify.sh and build.sh
5. Update flavour_matrix.md, README.md, docs/index.html
6. Run `make build FLAVOUR=<name> && make verify FLAVOUR=<name>`

### Bumping versions

- **Patch (1.0.0 -> 1.0.1):** Security fix, minor package update
- **Minor (1.0.0 -> 1.1.0):** New package added, major upstream update
- **Major (1.0.0 -> 2.0.0):** Base image change, breaking removal

Edit `images/<flavour>/VERSION` to trigger a new build.

## Commit Style

Conventional commits:

```
feat(ubuntu): add docker compose plugin
fix(node): raise size budget to 275MB
ci(build): add reproducibility check
docs(README): update flavour sizes
chore(renovate): wire docker-ce-cli tracking
```

## CI Pipeline

Every push to main triggers:

1. **Lint** (lint.yml): shellcheck, hadolint, VERSION validation, digest check, secret scan, BU consistency
2. **Build** (build.yml): Build, reproducibility check, verify, push, SBOM, cosign sign
3. **Nightly** (nightly.yml): Trivy security scan, secret scan, size regression

Pre-commit hooks run locally: shellcheck, hadolint, digest check, VERSION validation.

## Design Principles

See `.specs/00_requirements/pillars.md` for the full six pillars. In short:

1. **Deterministic:** Pinned versions, digest-pinned base image
2. **Thin:** Size budgets enforced by CI
3. **Secure:** No SUID (except sudo), no daemons, no secrets, Trivy scans
4. **Compatible:** Must work with standard Forgejo/GitHub Actions workflows
5. **Auditable:** SBOM, versions.lock, signed images
6. **Maintainable:** Renovate for automated updates

## License

Apache-2.0. By contributing, you agree your changes are licensed under the same terms.

## Community

- **Bug reports:** [GitHub Issues](https://github.com/WyattAu/RunnerImages/issues)
- **Feature requests:** [GitHub Discussions](https://github.com/WyattAu/RunnerImages/discussions)
- **Questions:** [GitHub Discussions Q&A](https://github.com/WyattAu/RunnerImages/discussions/categories/q-a)
