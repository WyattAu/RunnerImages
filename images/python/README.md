# runner-images/python

Python 3.12 with pip, venv, and native extension support. Includes g++, python3-dev, and libffi-dev for C extension compilation.

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
| Python | python3 3.12, pip, venv |
| Build extra | g++, python3-dev, libffi-dev, libssl-dev |
| System extra | sudo |

## Usage

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/python:1
    steps:
      - uses: actions/checkout@v4
      - run: pip install -r requirements.txt
      - run: pytest
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | 204MB |
| Uncompressed | 561MB |
| Layers | 3 |

## Changelog

- 1.0.0 (2026-06-07): Initial release
