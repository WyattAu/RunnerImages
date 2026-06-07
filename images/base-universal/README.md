# runner-images/base-universal

BU (Base Universal) layer only. Minimal CI image with git, curl, jq, make, gcc, and standard utilities. No Docker CLI, no Node.js, no Python, no sudo.

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

## Usage

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/base-universal:1
    steps:
      - uses: actions/checkout@v4
      - run: make lint
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | 190MB |
| Uncompressed | 524MB |
| Layers | 3 |

## Changelog

- 1.0.0 (2026-06-07): Initial release
