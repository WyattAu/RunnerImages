#!/bin/bash
set -euo pipefail

# Check upstream versions for all trackable flavours
# Outputs JSON array of {flavour, current_version, latest_version, bump_type}
# Usage: ./scripts/check-upstream-versions.sh

check_github_release() {
  local repo="$1"
  curl -s "https://api.github.com/repos/${repo}/releases/latest" | jq -r '.tag_name // empty' | sed 's/^v//'
}

check_nodejs() {
  # Get latest LTS version
  curl -s "https://nodejs.org/dist/index.json" | jq -r '[.[] | select(.lts != false)] | .[0].version' | sed 's/^v//'
}

check_go() {
  curl -s "https://go.dev/dl/?mode=json" | jq -r '[.[] | select(.stable == true)] | .[0].version' | sed 's/^go//'
}

check_rust() {
  curl -s "https://api.github.com/repos/rust-lang/rust/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

check_bun() {
  curl -s "https://api.github.com/repos/oven-sh/bun/releases/latest" | jq -r '.tag_name' | sed 's/^bun-v//'
}

check_zig() {
  curl -s "https://ziglang.org/download/index.json" | jq -r 'to_entries | [ .[] | select(.key | test("^[0-9]")) ] | .[0].key'
}

check_flutter() {
  curl -s "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json" | jq -r '[.releases[] | select(.channel == "stable")] | .[0].version'
}

check_swift() {
  curl -s "https://api.github.com/repos/swiftlang/swift/releases/latest" | jq -r '.tag_name' | sed 's/^swift-//;s/-RELEASE$//'
}

check_deno() {
  curl -s "https://api.github.com/repos/denoland/deno/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

check_elixir() {
  curl -s "https://api.github.com/repos/elixir-lang/elixir/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

check_kotlin() {
  curl -s "https://api.github.com/repos/JetBrains/kotlin/releases/latest" | jq -r '.tag_name' | sed 's/^v//'
}

classify_bump() {
  local old="$1"
  local new="$2"

  local old_major old_minor
  old_major=$(echo "$old" | cut -d. -f1)
  old_minor=$(echo "$old" | cut -d. -f2)

  local new_major new_minor
  new_major=$(echo "$new" | cut -d. -f1)
  new_minor=$(echo "$new" | cut -d. -f2)

  if [ "$new_major" != "$old_major" ]; then
    echo "major"
  elif [ "$new_minor" != "$old_minor" ]; then
    echo "minor"
  else
    echo "patch"
  fi
}

echo "["

FIRST=true

# Node.js
NODE_CURRENT=$(grep "ARG NODE_VERSION\|NODE_VERSION=" images/node/Dockerfile 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' || true)
NODE_LATEST=$(check_nodejs)
if [ -n "$NODE_LATEST" ] && [ "$NODE_CURRENT" != "$NODE_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"node\",\"tool\":\"Node.js\",\"current\":\"$NODE_CURRENT\",\"latest\":\"$NODE_LATEST\",\"bump\":\"$(classify_bump "$NODE_CURRENT" "$NODE_LATEST")\"}"
fi

# Go
GO_CURRENT=$(grep "ARG GO_VERSION" images/go/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
GO_LATEST=$(check_go)
if [ -n "$GO_LATEST" ] && [ "$GO_CURRENT" != "$GO_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"go\",\"tool\":\"Go\",\"current\":\"$GO_CURRENT\",\"latest\":\"$GO_LATEST\",\"bump\":\"$(classify_bump "$GO_CURRENT" "$GO_LATEST")\"}"
fi

# Rust
RUST_CURRENT=$(grep "ARG RUST_VERSION" images/rust/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
RUST_LATEST=$(check_rust)
if [ -n "$RUST_LATEST" ] && [ "$RUST_CURRENT" != "$RUST_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"rust\",\"tool\":\"Rust\",\"current\":\"$RUST_CURRENT\",\"latest\":\"$RUST_LATEST\",\"bump\":\"$(classify_bump "$RUST_CURRENT" "$RUST_LATEST")\"}"
fi

# Bun
BUN_CURRENT=$(grep "ARG BUN_VERSION" images/bun/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
BUN_LATEST=$(check_bun)
if [ -n "$BUN_LATEST" ] && [ "$BUN_CURRENT" != "$BUN_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"bun\",\"tool\":\"Bun\",\"current\":\"$BUN_CURRENT\",\"latest\":\"$BUN_LATEST\",\"bump\":\"$(classify_bump "$BUN_CURRENT" "$BUN_LATEST")\"}"
fi

# Zig
ZIG_CURRENT=$(grep "ARG ZIG_VERSION" images/zig/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
ZIG_LATEST=$(check_zig)
if [ -n "$ZIG_LATEST" ] && [ "$ZIG_CURRENT" != "$ZIG_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"zig\",\"tool\":\"Zig\",\"current\":\"$ZIG_CURRENT\",\"latest\":\"$ZIG_LATEST\",\"bump\":\"$(classify_bump "$ZIG_CURRENT" "$ZIG_LATEST")\"}"
fi

# Flutter
FLUTTER_CURRENT=$(grep "ARG FLUTTER_VERSION\|git clone.*flutter.*--branch" images/flutter/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1 || true)
FLUTTER_LATEST=$(check_flutter)
if [ -n "$FLUTTER_LATEST" ] && [ "$FLUTTER_CURRENT" != "$FLUTTER_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"flutter\",\"tool\":\"Flutter\",\"current\":\"$FLUTTER_CURRENT\",\"latest\":\"$FLUTTER_LATEST\",\"bump\":\"$(classify_bump "$FLUTTER_CURRENT" "$FLUTTER_LATEST")\"}"
fi

# Swift
SWIFT_CURRENT=$(grep "ARG SWIFT_VERSION" images/swift/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+' | head -1 || true)
SWIFT_LATEST=$(check_swift | cut -d. -f1,2)
if [ -n "$SWIFT_LATEST" ] && [ "$SWIFT_CURRENT" != "$SWIFT_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"swift\",\"tool\":\"Swift\",\"current\":\"$SWIFT_CURRENT\",\"latest\":\"$SWIFT_LATEST\",\"bump\":\"$(classify_bump "${SWIFT_CURRENT}.0" "${SWIFT_LATEST}.0")\"}"
fi

# Deno
DENO_CURRENT=$(grep "ARG DENO_VERSION" images/deno/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
DENO_LATEST=$(check_deno)
if [ -n "$DENO_LATEST" ] && [ "$DENO_CURRENT" != "$DENO_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"deno\",\"tool\":\"Deno\",\"current\":\"$DENO_CURRENT\",\"latest\":\"$DENO_LATEST\",\"bump\":\"$(classify_bump "$DENO_CURRENT" "$DENO_LATEST")\"}"
fi

# Elixir
ELIXIR_CURRENT=$(grep "ARG ELIXIR_VERSION" images/elixir/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
ELIXIR_LATEST=$(check_elixir)
if [ -n "$ELIXIR_LATEST" ] && [ "$ELIXIR_CURRENT" != "$ELIXIR_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"elixir\",\"tool\":\"Elixir\",\"current\":\"$ELIXIR_CURRENT\",\"latest\":\"$ELIXIR_LATEST\",\"bump\":\"$(classify_bump "$ELIXIR_CURRENT" "$ELIXIR_LATEST")\"}"
fi

# Kotlin
KOTLIN_CURRENT=$(grep "ARG KOTLIN_VERSION" images/kotlin/Dockerfile 2>/dev/null | grep -oP '\d+\.\d+\.\d+' || true)
KOTLIN_LATEST=$(check_kotlin)
if [ -n "$KOTLIN_LATEST" ] && [ "$KOTLIN_CURRENT" != "$KOTLIN_LATEST" ]; then
  [ "$FIRST" = false ] && echo ","
  FIRST=false
  echo "{\"flavour\":\"kotlin\",\"tool\":\"Kotlin\",\"current\":\"$KOTLIN_CURRENT\",\"latest\":\"$KOTLIN_LATEST\",\"bump\":\"$(classify_bump "$KOTLIN_CURRENT" "$KOTLIN_LATEST")\"}"
fi

echo ""
echo "]"
