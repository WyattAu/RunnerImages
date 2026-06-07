# runner-images/heavy

Kitchen sink for monorepos. Node.js 22 + Python 3.12 + Docker CLI + full build tools in one image.

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
| Docker | docker-ce-cli |
| Node.js | node 22.22.3, npm, yarn, pnpm |
| Python | python3 3.12, pip, venv |
| Build extra | g++, pkg-config, python3-dev, libffi-dev, libssl-dev |
| System extra | sudo, iputils-ping, net-tools |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/heavy:1
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: pip install -r requirements.txt
      - run: docker build -t app .
      - run: make test
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | 282MB |
| Uncompressed | 818MB |
| Layers | 3 |

## Changelog

- 1.0.0 (2026-06-07): Initial release
