# runner-images/rust-node

Combined Node.js + Rust runner image for Forgejo Actions.

## Contents

- **Node.js** 22.22.3 LTS (npm, yarn, pnpm)
- **Rust** 1.96.0 stable (cargo, rustc, rustfmt, clippy)
- **Build tools** (g++, pkg-config, libssl-dev, make, python3)
- **Base** (git, git-lfs, curl, jq, yq, openssh-client)

## Usage

```yaml
# In .forgejo/workflows/ci.yml
jobs:
  test:
    runs-on: ubuntu-latest
    container:
      image: ghcr.io/wyattau/runner-images/rust-node:2.0.0
    steps:
      - uses: actions/checkout@v4
      - run: cargo test
      - run: npm ci && npm test
```

No need to install Rust or Node — both are pre-installed.
