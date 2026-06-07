#!/bin/bash
set -euo pipefail

# Build script for Forgejo Actions runner images
# Usage: ./scripts/build.sh <flavour> [--push] [--sign] [--sbom] [--scan]

FLAVOUR="${1:?"Usage: $0 <flavour> [--push] [--sign] [--sbom] [--scan]"}"

PUSH=false
SIGN=false
SBOM=false
SCAN=false
REPO="${REPO:-ghcr.io/wyattau/runner-images}"
COSIGN_KEY="${COSIGN_KEY:-$HOME/.cosign/cosign.key}"
FLAVOUR_DIR="images/$FLAVOUR"

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

MAJOR="${VERSION%%.*}"
MINOR="${VERSION%.*}"

IMAGE="$REPO/$FLAVOUR:$VERSION"
LATEST="$REPO/$FLAVOUR:latest"
MAJOR_TAG="$REPO/$FLAVOUR:$MAJOR"
MINOR_TAG="$REPO/$FLAVOUR:$MINOR"

echo "=== Building $FLAVOUR:$VERSION ==="

docker build \
  --no-cache \
  --platform linux/amd64 \
  --progress=plain \
  --build-arg IMAGE_VERSION="$VERSION" \
  --build-arg SOURCE_DATE_EPOCH=0 \
  -t "$IMAGE" \
  -t "$LATEST" \
  -t "$MAJOR_TAG" \
  -t "$MINOR_TAG" \
  "$FLAVOUR_DIR/"

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
  flutter)        COMP_BUDGET=900; UNCOMP_BUDGET=2500 ;;
  ubuntu)         COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
  node)           COMP_BUDGET=275; UNCOMP_BUDGET=800 ;;
  python)         COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
  rust)           COMP_BUDGET=550; UNCOMP_BUDGET=1800 ;;
  go)             COMP_BUDGET=350; UNCOMP_BUDGET=900 ;;
  java)           COMP_BUDGET=400; UNCOMP_BUDGET=900 ;;
  dotnet)         COMP_BUDGET=400; UNCOMP_BUDGET=1100 ;;
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

# Push
if [ "$PUSH" = true ]; then
  echo ""
  echo "=== Pushing to $REPO ==="

  for TAG in "$IMAGE" "$LATEST" "$MAJOR_TAG" "$MINOR_TAG"; do
    if docker manifest inspect "$TAG" >/dev/null 2>&1; then
      echo "WARNING: $TAG already exists in remote, skipping"
    else
      docker push "$TAG"
      echo "Pushed: $TAG"
    fi
  done
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
