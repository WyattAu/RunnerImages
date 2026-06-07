# runner-images/bun

Bun 1.3.14 with npm and pnpm. Includes g++ and python3 for native module compilation (node-gyp).

## Base

`ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54`

## Contents

| Category | Packages |
|----------|----------|
| VCS | git, git-lfs, openssh-client |
| Build | make, build-essential, gcc, g++ |
| Data | jq, yq |
| HTTP | curl, wget |
| Archive | zip, unzip, zstd, tar, gzip |
| Crypto | ca-certificates, openssl |
| System | diffutils, patch, file, tree |
| Bun | bun 1.3.14, npm, pnpm |
| Build extra | g++ (explicit), python3 (node-gyp) |
| System extra | sudo |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/bun:1
    steps:
      - uses: actions/checkout@v4
      - run: bun install
      - run: bun test
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | ~250MB |
| Uncompressed | ~740MB |
| Layers | 3 |

## Changelog

- 1.1.0 (2026-06-07): Initial release
