# Security Policy

## Supported Versions

| Version | Supported |
| ------- | --------- |
| 1.0.x   | Yes       |

## Reporting a Vulnerability

Report security vulnerabilities by opening a private security advisory at:

https://github.com/WyattAu/RunnerImages/security/advisories/new

Do not file public issues for security vulnerabilities.

## Response Times

| Severity | Response | Resolution |
|----------|----------|------------|
| Critical | 24 hours | 24 hours |
| High | 48 hours | 48 hours |
| Medium | 7 days | 7 days |
| Low | 30 days | 30 days |

## Security Scanning

All images are automatically scanned:

- **Trivy vulnerability scan** -- every build and nightly, fails on CRITICAL/HIGH CVEs
- **Secret scan** -- every build and nightly, fails on any finding
- **SUID binary scan** -- every build, fails on unexpected SUID binaries
- **World-writable file scan** -- every build, fails on any finding
- **SBOM generation** -- SPDX format, published as CI artifact
- **Image signing** -- cosign keyless signing with GitHub OIDC identity

## Supply Chain

| Control | Status |
|---------|--------|
| Base image pinned by SHA256 digest | Yes |
| All packages version-pinned | Yes |
| Node.js tarball SHA256 verified | Yes |
| SBOM (SPDX) generated per build | Yes |
| Images signed with cosign | Yes |
| Automated dependency updates (Renovate) | Yes |
| Pre-commit hooks for digest validation | Yes |
