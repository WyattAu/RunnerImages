#!/bin/bash
set -euo pipefail

# Bump version for a specific flavour
# Usage: ./scripts/bump-version.sh <flavour> <new-version>
#
# Updates:
#   - images/<flavour>/VERSION
#   - images/<flavour>/README.md (version references)
#   - images/*/Dockerfile (if base-universal is bumped, updates all FROM refs)

FLAVOUR="${1:?"Usage: $0 <flavour> <new-version>"}"
NEW_VERSION="${2:?"Usage: $0 <flavour> <new-version>"}"

FLAVOUR_DIR="images/$FLAVOUR"

if [ ! -d "$FLAVOUR_DIR" ]; then
  echo "ERROR: Flavour directory '$FLAVOUR_DIR' does not exist"
  exit 1
fi

# Validate semver
if ! echo "$NEW_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
  echo "ERROR: '$NEW_VERSION' is not valid semver (expected MAJOR.MINOR.PATCH)"
  exit 1
fi

OLD_VERSION=$(tr -d '[:space:]' < "$FLAVOUR_DIR/VERSION")

if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  echo "INFO: $FLAVOUR already at $NEW_VERSION, nothing to do"
  exit 0
fi

echo "=== Bumping $FLAVOUR: $OLD_VERSION -> $NEW_VERSION ==="

# 1. Update VERSION file
echo "$NEW_VERSION" > "$FLAVOUR_DIR/VERSION"
echo "  Updated $FLAVOUR_DIR/VERSION"

# 2. Update OCI version label in Dockerfile
if [ -f "$FLAVOUR_DIR/Dockerfile" ]; then
  sed -i "s|LABEL runner.base.tag=\"[^\"]*\"|LABEL runner.base.tag=\"$NEW_VERSION\"|" "$FLAVOUR_DIR/Dockerfile"
  echo "  Updated Dockerfile OCI labels"
fi

# 3. Update README.md version references
if [ -f "$FLAVOUR_DIR/README.md" ]; then
  sed -i "s|$OLD_VERSION|$NEW_VERSION|g" "$FLAVOUR_DIR/README.md"
  echo "  Updated README.md"
fi

# 4. If base-universal is bumped, update all child Dockerfiles
if [ "$FLAVOUR" = "base-universal" ]; then
  echo "  base-universal bumped -- updating all child Dockerfiles..."
  for dockerfile in images/*/Dockerfile; do
    flavour_name=$(echo "$dockerfile" | sed 's|images/||;s|/Dockerfile||')
    if [ "$flavour_name" != "base-universal" ]; then
      sed -i "s|FROM ghcr.io/wyattau/runner-images/base-universal:[^ ]* AS bu-base|FROM ghcr.io/wyattau/runner-images/base-universal:$NEW_VERSION AS bu-base|" "$dockerfile"
      sed -i "s|LABEL runner.base.tag=\"[^\"]*\"|LABEL runner.base.tag=\"$NEW_VERSION\"|" "$dockerfile"
      echo "    Updated $flavour_name/Dockerfile"
    fi
  done
  # Also update build.sh and verify.sh base version fallback
  sed -i "s|BASE_VERSION=.*echo \"[^\"]*\"|BASE_VERSION=\$(tr -d '[:space:]' < \"images/base-universal/VERSION\" 2>/dev/null || echo \"$NEW_VERSION\")|" scripts/build.sh 2>/dev/null || true
fi

echo "=== Done: $FLAVOUR now at $NEW_VERSION ==="
