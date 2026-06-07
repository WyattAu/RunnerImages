# runner-images/ubuntu

Forgejo Actions runner image: Ubuntu 24.04 with Docker CLI, Node.js 22, and build tools.

## Base

ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54

## Contents

| Category | Packages | Version |
|----------|----------|---------|
| VCS | git, git-lfs, openssh-client | 1:2.43.0, 3.4.1, 1:9.6p1 |
| Build | make, build-essential, g++, pkg-config | 4.3, 12.10ubuntu1, 4:13.2.0, 1.8.1 |
| Data | jq, yq | 1.7.1, 3.1.0 |
| HTTP | curl, wget | 8.5.0, 1.21.4 |
| Archive | zip, unzip, zstd, tar, gzip | 3.0, 6.0, 1.5.5, 1.35, 1.12 |
| Crypto | ca-certificates, openssl | 20240203, 3.0.13 |
| Docker | docker-ce-cli | Docker repo |
| Node.js | node | 22.22.3 |
| System | sudo, diffutils, patch, file, tree, iputils-ping, net-tools | 1.9.15, 1:3.10, 2.7.6, 1:5.45, 2.1.1, 3:20240117, 2.10 |

## Usage

```yaml
runs-on: [self-hosted, ubuntu-latest]
container:
  image: ghcr.io/wyattau/runner-images/ubuntu:1.0.0
```

## Size

| Metric | Value |
|--------|-------|
| Layers | 3 |
| Compressed | <=225MB |
| Uncompressed | <=630MB |

## Labels

```
ubuntu-latest:docker://ghcr.io/wyattau/runner-images/ubuntu:1.0.0
```

## Changelog

- 1.0.0 (2026-06-07): Initial release
