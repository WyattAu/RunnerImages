# Swift Runner Image

Swift 6.1 for Forgejo Actions CI. amd64 only (Swift has no Linux arm64 tarballs).

## Tools

- Swift 6.1 (official tarball from swift.org)
- Swift Package Manager (spm)
- libncurses5, libsqlite3, libcurl4, libxml2
- sudo (passwordless)

## Usage

```yaml
container:
  image: ghcr.io/wyattau/runner-images/swift:1
```

## Verify

```bash
swift --version   # Swift 6.1
```
