# rust-full

Forgejo Actions runner image with Rust and extended tooling for WebAssembly, cross-compilation, and database development.

## Base

Includes everything from the **rust** flavour:

- Rust 1.96.0 (via rustup)
- cargo, rustup

## Additional tools

| Tool | Source | Purpose |
|------|--------|---------|
| `wasm-pack` | GitHub release binary | Build, test, and publish Rust-generated WebAssembly packages |
| `cross` | GitHub release binary | Cross-compilation for Rust via Docker or QEMU |
| `protobuf-compiler` | apt | Protobuf code generation (`protoc`) |
| `libsqlite3-dev` | apt | SQLite development headers for `sqlx` |
| `cmake` | apt | Build native dependencies that require CMake |
| `sqlx-cli` | cargo install | Async SQL CLI toolkit with compile-time checked queries (SQLite support) |
