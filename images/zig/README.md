# Zig Runner Image

Zig 0.16.0 for Forgejo Actions CI. Multi-arch (amd64 + arm64).

## Tools

- Zig 0.16.0 (official tarball, SHA256 verified)
- sudo (passwordless)

## Usage

```yaml
container:
  image: ghcr.io/wyattau/runner-images/zig:1
```

## Verify

```bash
zig version   # 0.16.0
```
