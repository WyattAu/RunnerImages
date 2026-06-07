# runner-images/rust

Rust 1.96.0 with cargo, rustup, g++, and libssl-dev.

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
| Rust | rust 1.96.0, cargo, rustup |
| Build extra | g++, libssl-dev |
| System extra | sudo |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/rust:1
      env:
        PATH: /usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    steps:
      - uses: actions/checkout@v4
      - run: cargo build --release
      - run: cargo test
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | 471MB |
| Uncompressed | 1789MB |
| Layers | 3 |

## Changelog

- 1.0.0 (2026-06-07): Initial release
