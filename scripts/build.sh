#!/bin/bash
set -euo pipefail

# Build script for Forgejo Actions runner images (B1 layered architecture)
# Usage: ./scripts/build.sh <flavour> [--push] [--sign] [--sbom] [--scan]

FLAVOUR="${1:?"Usage: $0 <flavour> [--push] [--sign] [--sbom] [--scan]"}"

PUSH=false
SIGN=false
SBOM=false
SCAN=false
NO_CACHE=true
REPO="${REPO:-ghcr.io/wyattau/runner-images}"
COSIGN_KEY="${COSIGN_KEY:-$HOME/.cosign/cosign.key}"
FLAVOUR_DIR="images/$FLAVOUR"
PLATFORM="${PLATFORM:-linux/amd64}"
ARCH="${PLATFORM#linux/}"

# Validate flavour directory
if [ ! -d "$FLAVOUR_DIR" ]; then
  echo "ERROR: Flavour directory '$FLAVOUR_DIR' does not exist"
  exit 1
fi

if [ ! -f "$FLAVOUR_DIR/VERSION" ]; then
  echo "ERROR: VERSION file not found at '$FLAVOUR_DIR/VERSION'"
  exit 1
fi

if [ ! -f "$FLAVOUR_DIR/Dockerfile" ]; then
  echo "ERROR: Dockerfile not found at '$FLAVOUR_DIR/Dockerfile'"
  exit 1
fi

VERSION=$(tr -d '[:space:]' < "$FLAVOUR_DIR/VERSION")

# ---------------------------------------------------------------------------
# B1: Ensure base-universal image exists before building child flavours
# ---------------------------------------------------------------------------
if [ "$FLAVOUR" != "base-universal" ]; then
  BASE_VERSION=$(tr -d '[:space:]' < "images/base-universal/VERSION" 2>/dev/null || echo "2.0.0")
  BASE_IMAGE="$REPO/base-universal:${BASE_VERSION}-${ARCH}"
  BASE_IMAGE_LATEST="$REPO/base-universal:latest"
  BASE_FROM_REF="$REPO/base-universal:${BASE_VERSION}"

  # Check if base image exists locally
  if ! docker image inspect "$BASE_IMAGE" >/dev/null 2>&1 && \
     ! docker image inspect "$BASE_IMAGE_LATEST" >/dev/null 2>&1; then
    echo "=== Base-universal image not found locally. Building it first... ==="
    PLATFORM="$PLATFORM" ./scripts/build.sh base-universal
    echo ""
    echo "=== Resuming build of $FLAVOUR ==="
  fi

  # Ensure the base image is tagged with the exact reference child Dockerfiles expect
  if ! docker image inspect "$BASE_FROM_REF" >/dev/null 2>&1; then
    if docker image inspect "$BASE_IMAGE" >/dev/null 2>&1; then
      docker tag "$BASE_IMAGE" "$BASE_FROM_REF"
    elif docker image inspect "$BASE_IMAGE_LATEST" >/dev/null 2>&1; then
      docker tag "$BASE_IMAGE_LATEST" "$BASE_FROM_REF"
    fi
  fi
fi

# Semver validation (MAJOR.MINOR.PATCH with optional pre-release)
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
  echo "ERROR: VERSION '$VERSION' is not valid semver (expected MAJOR.MINOR.PATCH)"
  exit 1
fi

# Parse argument flags from second positional param onward
for arg in "${@:2}"; do
  case "$arg" in
    --push) PUSH=true ;;
    --sign) SIGN=true ;;
    --sbom) SBOM=true ;;
    --scan) SCAN=true ;;
    --no-cache) NO_CACHE=true ;;
    --cache) NO_CACHE=false ;;
  esac
done

# Dependency checks
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required but not found in PATH"
  exit 1
fi

if [ "$SIGN" = true ] && ! command -v cosign >/dev/null 2>&1; then
  echo "ERROR: cosign is required for --sign but not found in PATH"
  exit 1
fi

if [ "$SBOM" = true ] && ! command -v syft >/dev/null 2>&1; then
  echo "ERROR: syft is required for --sbom but not found in PATH"
  exit 1
fi

if [ "$SCAN" = true ] && ! command -v trivy >/dev/null 2>&1; then
  echo "ERROR: trivy is required for --scan but not found in PATH"
  exit 1
fi

# Cache directory for downloaded tarballs (CI optimization)
CACHE_DIR="${CACHE_DIR:-/tmp/runner-images-cache}"
mkdir -p "$CACHE_DIR"

echo "=== Building $FLAVOUR:$VERSION ($PLATFORM) ==="

IMAGE="$REPO/$FLAVOUR:$VERSION-$ARCH"

# Build with retry (2 attempts with backoff, adapted from Evergreen pattern)
MAX_ATTEMPTS=2
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT + 1))

  CACHE_FLAG=""
  if [ "$NO_CACHE" = true ]; then CACHE_FLAG="--no-cache"; fi

  if docker build \
    ${CACHE_FLAG} \
    --output=type=docker \
    --platform "$PLATFORM" \
    --progress=plain \
    --build-arg IMAGE_VERSION="$VERSION" \
    --build-arg SOURCE_DATE_EPOCH=0 \
    ${SNAPSHOT_DATE:+--build-arg SNAPSHOT_DATE="$SNAPSHOT_DATE"} \
    -t "$IMAGE" \
    "$FLAVOUR_DIR/"; then
    echo "Build succeeded on attempt $ATTEMPT"
    break
  else
    if [ $ATTEMPT -lt $MAX_ATTEMPTS ]; then
      echo "Build failed on attempt $ATTEMPT, retrying in 5s..."
      sleep 5
    else
      echo "ERROR: Build failed after $MAX_ATTEMPTS attempts"
      exit 1
    fi
  fi
done

DIGEST=$(docker inspect --format '{{.Id}}' "$IMAGE")

COMPRESSED_BYTES=$(docker save "$IMAGE" | gzip -6 | wc -c)
COMPRESSED_MB=$((COMPRESSED_BYTES / 1024 / 1024))

UNCOMPRESSED_BYTES=$(docker inspect --format '{{.Size}}' "$IMAGE")
UNCOMPRESSED_MB=$((UNCOMPRESSED_BYTES / 1024 / 1024))

echo ""
echo "=== Build complete ==="
echo "Image: $IMAGE"
echo "Digest: $DIGEST"
echo "Compressed: ${COMPRESSED_MB}MB"
echo "Uncompressed: ${UNCOMPRESSED_MB}MB"

case "$FLAVOUR" in
  heavy)          COMP_BUDGET=350; UNCOMP_BUDGET=900 ;;
  flutter)        COMP_BUDGET=2200; UNCOMP_BUDGET=3800 ;;
  ubuntu)         COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
  node)           COMP_BUDGET=275; UNCOMP_BUDGET=800 ;;
  python)         COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
  rust)           COMP_BUDGET=550; UNCOMP_BUDGET=1800 ;;
  rust-node)      COMP_BUDGET=600; UNCOMP_BUDGET=2000 ;;
  rust-full)      COMP_BUDGET=600; UNCOMP_BUDGET=2000 ;;
  go)             COMP_BUDGET=350; UNCOMP_BUDGET=900 ;;
  java)           COMP_BUDGET=400; UNCOMP_BUDGET=900 ;;
  dotnet)         COMP_BUDGET=400; UNCOMP_BUDGET=1100 ;;
  bun)            COMP_BUDGET=300; UNCOMP_BUDGET=850 ;;
  c)              COMP_BUDGET=250; UNCOMP_BUDGET=700 ;;
  deno)           COMP_BUDGET=250; UNCOMP_BUDGET=700 ;;
  elixir)         COMP_BUDGET=400; UNCOMP_BUDGET=1000 ;;
  haskell)        COMP_BUDGET=650; UNCOMP_BUDGET=2500 ;;
  kotlin)         COMP_BUDGET=550; UNCOMP_BUDGET=1300 ;;
  pnpm)           COMP_BUDGET=280; UNCOMP_BUDGET=780 ;;
  nix)            COMP_BUDGET=310; UNCOMP_BUDGET=800 ;;
  r-lang)         COMP_BUDGET=500; UNCOMP_BUDGET=1500 ;;
  ruby)           COMP_BUDGET=350; UNCOMP_BUDGET=900 ;;
  php)            COMP_BUDGET=300; UNCOMP_BUDGET=800 ;;
  zig)            COMP_BUDGET=350; UNCOMP_BUDGET=850 ;;
  swift)          COMP_BUDGET=1100; UNCOMP_BUDGET=3500 ;;
  base-universal) COMP_BUDGET=200; UNCOMP_BUDGET=530 ;;
  *)              COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
esac

if [ "$COMPRESSED_MB" -gt "$COMP_BUDGET" ]; then
  echo "FAIL: Compressed size ${COMPRESSED_MB}MB exceeds budget ${COMP_BUDGET}MB"
  exit 1
fi

if [ "$UNCOMPRESSED_MB" -gt "$UNCOMP_BUDGET" ]; then
  echo "FAIL: Uncompressed size ${UNCOMPRESSED_MB}MB exceeds budget ${UNCOMP_BUDGET}MB"
  exit 1
fi

echo "Size checks: PASS (budgets: compressed=${COMP_BUDGET}MB, uncompressed=${UNCOMP_BUDGET}MB)"

# SBOM generation
if [ "$SBOM" = true ]; then
  echo ""
  echo "=== Generating SBOM with syft ==="
  syft "$IMAGE" -o spdx-json > "${FLAVOUR}-${VERSION}-sbom.spdx.json"
  echo "SBOM written to ${FLAVOUR}-${VERSION}-sbom.spdx.json"
fi

# Security scan
if [ "$SCAN" = true ]; then
  echo ""
  echo "=== Scanning with trivy ==="
  trivy image --severity HIGH,CRITICAL "$IMAGE"
fi

# Push (per-arch tag only; manifest job creates multi-arch tags)
if [ "$PUSH" = true ]; then
  echo ""
  echo "=== Pushing $IMAGE to $REPO ==="
  docker push "$IMAGE"
  echo "Pushed: $IMAGE"

  # For base-universal: also tag and push as latest for child images
  if [ "$FLAVOUR" = "base-universal" ]; then
    LATEST_TAG="$REPO/base-universal:latest-${ARCH}"
    docker tag "$IMAGE" "$LATEST_TAG"
    docker push "$LATEST_TAG"
    echo "Pushed: $LATEST_TAG"
  fi
fi

# Sign
if [ "$SIGN" = true ]; then
  echo ""
  echo "=== Signing with cosign ==="

  for TAG in "$IMAGE" "$LATEST"; do
    cosign sign --key "$COSIGN_KEY" "$TAG"
    echo "Signed: $TAG"
  done
fi

echo ""
echo "=== Done ==="
