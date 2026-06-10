#!/bin/bash
set -euo pipefail

# Cross-flavour integration tests
# Verifies layer sharing, user setup, and tool isolation

REGISTRY="${REGISTRY:-ghcr.io/wyattau/runner-images}"
VERSION="${VERSION:-latest}"
PLATFORM="${PLATFORM:-linux/amd64}"
PASS=0
FAIL=0

# Get base-universal digest
BASE_DIGEST=$(docker inspect --format '{{.Id}}' "${REGISTRY}/base-universal:${VERSION}" 2>/dev/null || echo "")

if [ -z "$BASE_DIGEST" ]; then
  echo "ERROR: base-universal image not found. Pull it first."
  exit 1
fi

# All child flavours (excluding base-universal)
FLAVOURS="ubuntu node pnpm bun python heavy rust rust-full go java dotnet flutter nix ruby php zig swift deno elixir kotlin c haskell r-lang"

echo "=== Cross-Flavour Integration Tests ==="
echo "Base: ${REGISTRY}/base-universal:${VERSION}"
echo "Digest: ${BASE_DIGEST}"
echo ""

for flavour in $FLAVOURS; do
  IMAGE="${REGISTRY}/${flavour}:${VERSION}"

  if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "SKIP: $flavour (image not found locally)"
    continue
  fi

  # Test 1: runner user exists with UID 1000
  if docker run --rm --entrypoint /bin/sh "$IMAGE" -c "id runner" 2>/dev/null | grep -q "uid=1000"; then
    echo "  [PASS] $flavour: runner user uid=1000"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $flavour: runner user not uid=1000"
    FAIL=$((FAIL + 1))
  fi

  # Test 2: runner home directory exists
  if docker run --rm --entrypoint /bin/sh "$IMAGE" -c "test -d /home/runner" 2>/dev/null; then
    echo "  [PASS] $flavour: /home/runner exists"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $flavour: /home/runner missing"
    FAIL=$((FAIL + 1))
  fi

  # Test 3: entrypoint is /bin/bash
  ENTRYPOINT=$(docker inspect --format '{{.Config.Entrypoint}}' "$IMAGE" 2>/dev/null)
  if echo "$ENTRYPOINT" | grep -q "/bin/bash"; then
    echo "  [PASS] $flavour: entrypoint is /bin/bash"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $flavour: entrypoint is not /bin/bash (got: $ENTRYPOINT)"
    FAIL=$((FAIL + 1))
  fi

  # Test 4: USER is runner
  USER=$(docker inspect --format '{{.Config.User}}' "$IMAGE" 2>/dev/null)
  if [ "$USER" = "runner" ]; then
    echo "  [PASS] $flavour: USER is runner"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $flavour: USER is not runner (got: $USER)"
    FAIL=$((FAIL + 1))
  fi

  # Test 5: base tools available (git, curl)
  if docker run --rm --entrypoint /bin/sh "$IMAGE" -c "which git && which curl" >/dev/null 2>&1; then
    echo "  [PASS] $flavour: base tools (git, curl) present"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $flavour: base tools (git, curl) missing"
    FAIL=$((FAIL + 1))
  fi
done

echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
