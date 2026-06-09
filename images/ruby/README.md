# Ruby Runner Image

Ruby 3.4 + bundler + gem for Forgejo Actions CI.

## Tools

- Ruby 3.4.4 (compiled from source)
- bundler (latest via gem)
- libssl-dev, libffi-dev, libyaml-dev, zlib1g-dev, libreadline-dev
- sudo (passwordless)

## Usage

```yaml
container:
  image: ghcr.io/wyattau/runner-images/ruby:1
```

## Verify

```bash
ruby --version   # ruby 3.4.4
gem --version
bundler --version
```
