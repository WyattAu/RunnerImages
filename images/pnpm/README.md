# runner-images/pnpm

Node.js 22 LTS with pnpm only (no yarn). Includes g++ and python3 for native module compilation (node-gyp). Lighter than the full node flavour.

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
| Node.js | node 22.22.3, npm, pnpm |
| Build extra | g++ (explicit), python3 (node-gyp) |
| System extra | sudo |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/pnpm:1
    steps:
      - uses: actions/checkout@v4
      - run: pnpm install
      - run: pnpm test
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | ~250MB |
| Uncompressed | ~720MB |
| Layers | 3 |

## Changelog

- 1.1.0 (2026-06-07): Initial release
