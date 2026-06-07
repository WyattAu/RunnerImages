# runner-images/go

Go 1.26.4 with standard toolchain.

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
| Go | go 1.26.4 |
| System extra | sudo |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/go:1
      env:
        PATH: /usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    steps:
      - uses: actions/checkout@v4
      - run: go build ./...
      - run: go test ./...
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | TBD |
| Uncompressed | TBD |
| Layers | 3 |

## Changelog

- 1.0.0 (2026-06-07): Initial release
