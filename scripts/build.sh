#!/bin/bash
set -euo pipefail

# Build script for Forgejo Actions runner images
# Usage: ./scripts/build.sh <flavour> [--push] [--sign]

FLAVOUR=${1:?"Usage: $0 <flavour> [--push] [--sign]"}
PUSH=false
SIGN=false
REPO="ghcr.io/wyattau/runner-images"
VERSION=$(cat "images/$FLAVOUR/VERSION" | tr -d '[:space:]')

shift || true
for arg in "$@"; do
  case $arg in
    --push) PUSH=true ;;
    --sign) SIGN=true ;;
  esac
done

IMAGE="$REPO/$FLAVOUR:$VERSION"
LATEST="$REPO/$FLAVOUR:latest"

echo "=== Building $FLAVOUR:$VERSION ==="

# Build
docker build \
  --no-cache \
  -t "$IMAGE" \
  -t "$LATEST" \
  "images/$FLAVOUR/"

# Get digests
DIGEST=$(docker inspect --format '{{.Id}}' "$IMAGE")
COMPRESSED=$(docker save "$IMAGE" | gzip -9 | wc -c | awk '{printf "%.1f", $1/1024/1024}')
UNCOMPRESSED=$(docker inspect --format '{{.Size}}' "$IMAGE" | awk '{printf "%.1f", $1/1024/1024}')

echo ""
echo "=== Build complete ==="
echo "Image: $IMAGE"
echo "Digest: $DIGEST"
echo "Compressed: ${COMPRESSED}MB"
echo "Uncompressed: ${UNCOMPRESSED}MB"

# Size checks
COMPRESSED_INT=${COMPRESSED%.*}
UNCOMPRESSED_INT=${UNCOMPRESSED%.*}

if [ "$COMPRESSED_INT" -gt 225 ]; then
  echo "FAIL: Compressed size ${COMPRESSED}MB exceeds budget 225MB"
  exit 1
fi

if [ "$UNCOMPRESSED_INT" -gt 630 ]; then
  echo "FAIL: Uncompressed size ${UNCOMPRESSED}MB exceeds budget 630MB"
  exit 1
fi

echo "Size checks: PASS"

# Push
if [ "$PUSH" = true ]; then
  echo ""
  echo "=== Pushing to $REPO ==="
  docker push "$IMAGE"
  docker push "$LATEST"
  echo "Pushed: $IMAGE"
  echo "Pushed: $LATEST"
fi

# Sign
if [ "$SIGN" = true ]; then
  echo ""
  echo "=== Signing with cosign ==="
  cosign sign --key ~/.cosign/cosign.key "$IMAGE"
  echo "Signed: $IMAGE"
fi

echo ""
echo "=== Done ==="
