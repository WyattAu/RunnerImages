# runner-images/java

OpenJDK 21 with Maven.

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
| Java | openjdk 21, maven |
| System extra | sudo |

## Usage

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/java:1
      env:
        JAVA_HOME: /usr/lib/jvm/java-21-openjdk-amd64
    steps:
      - uses: actions/checkout@v4
      - run: mvn package
      - run: mvn test
```

## Size

| Metric | Value |
|--------|-------|
| Compressed | TBD |
| Uncompressed | TBD |
| Layers | 3 |

## Changelog

- 1.0.0 (2026-06-07): Initial release
