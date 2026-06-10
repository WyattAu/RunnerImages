#!/bin/bash
set -euo pipefail

# Discover which images need to be built
# Usage: ./scripts/discover-images.sh <mode> [args...]
#
# Modes:
#   changed [base]      - Images changed since base (default: HEAD~1)
#   all                 - All images with a Dockerfile
#   tier <tier>         - All images in given tier (not implemented yet)
#   images <a,b,c>      - Specific comma-separated images
#
# Output: JSON matrix for GitHub Actions {"flavour": [...], "child_flavours": [...]}

IMAGES_DIR="images"

list_all_images() {
  for d in "$IMAGES_DIR"/*/; do
    name=$(basename "$d")
    if [ "$name" != "shared" ] && [ -f "$d/Dockerfile" ]; then
      echo "$name"
    fi
  done | sort
}

get_changed_images() {
  local base="${1:-HEAD~1}"

  # Check if we're in a PR or on main
  if [ -n "${GITHUB_BASE_REF:-}" ]; then
    base="origin/${GITHUB_BASE_REF}"
  fi

  # Find which image directories had changes
  local changed
  changed=$(git diff --name-only "${base}" HEAD -- "$IMAGES_DIR/" 2>/dev/null \
    | grep "^${IMAGES_DIR}/" \
    | sed "s|^${IMAGES_DIR}/||" \
    | sed 's|/.*||' \
    | sort -u)

  # Also check shared infrastructure
  local shared_changed
  shared_changed=$(git diff --name-only "${base}" HEAD \
    -- scripts/ .github/workflows/build.yml .github/workflows/_build-reusable.yml \
    2>/dev/null || true)

  if [ -n "$changed" ]; then
    echo "$changed"
  elif [ -n "$shared_changed" ]; then
    # Shared infra changed -- only rebuild base-universal (children inherit from pushed base)
    echo "base-universal"
  fi
}

list_specific_images() {
  local csv="$1"
  echo "$csv" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | while read -r img; do
    if [ -f "$IMAGES_DIR/$img/Dockerfile" ]; then
      echo "$img"
    else
      echo "WARN: Image '$img' not found, skipping" >&2
    fi
  done
}

# Main logic
MODE="${1:-changed}"

case "$MODE" in
  changed)
    BASE="${2:-HEAD~1}"
    IMAGES=$(get_changed_images "$BASE")
    ;;
  all)
    IMAGES=$(list_all_images)
    ;;
  images)
    IMAGES=$(list_specific_images "${2:-}")
    ;;
  *)
    echo "ERROR: Unknown mode '$MODE'" >&2
    echo "Usage: $0 <changed|all|images> [args...]" >&2
    exit 1
    ;;
esac

if [ -z "$IMAGES" ]; then
  echo '{"flavour":[],"child_flavours":[],"has_base":false,"has_children":false}'
  exit 0
fi

# Separate base-universal from children
HAS_BASE=false
CHILDREN=""

for img in $IMAGES; do
  if [ "$img" = "base-universal" ]; then
    HAS_BASE=true
  else
    CHILDREN="${CHILDREN}${CHILDREN:+ }${img}"
  fi
done

# Build JSON output
FLAVOUR_LIST=$(echo "base-universal $CHILDREN" | tr ' ' '\n' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')
CHILD_LIST=$(echo "$CHILDREN" | tr ' ' '\n' | sort -u | jq -R -s -c 'split("\n") | map(select(length > 0))')

echo "{\"flavour\":${FLAVOUR_LIST},\"child_flavours\":${CHILD_LIST},\"has_base\":${HAS_BASE},\"has_children\":$([ -n "$CHILDREN" ] && echo true || echo false)}"
