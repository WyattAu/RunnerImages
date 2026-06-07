# runner-images/nix

Nix package manager (single-user installation, flake-ready). For projects using Nix flakes, `nix develop`, or `nix build`.

## Base

`ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54`

## Contents

| Category | Packages |
|----------|----------|
| VCS | git, git-lfs, openssh-client |
| Build | make, build-essential |
| Data | jq, yq |
| HTTP | curl, wget |
| Archive | zip, unzip, zstd, tar, gzip |
| Crypto | ca-certificates, openssl |
| System | diffutils, patch, file, tree |
| Nix | nix (single-user, via official installer) |
| System extra | sudo, xz-utils |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/nix:1
    steps:
      - uses: actions/checkout@v4
      - run: nix build
      - run: nix flake check
```

## Notes

- Nix is installed in single-user mode (`--no-daemon`) under the `runner` user.
- `NIX_PATH` is set to `nixpkgs=channel:nixos-unstable` by default.
- Flake support is included out of the box.

## Size

| Metric | Value |
|--------|-------|
| Compressed | ~280MB |
| Uncompressed | ~780MB |
| Layers | 3 |

## Changelog

- 1.1.0 (2026-06-07): Initial release
