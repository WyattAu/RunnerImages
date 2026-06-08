#!/usr/bin/env bash
# check-bu-consistency.sh
# Verifies B1 layered architecture: child images inherit from base-universal.
#
# Rules:
#   - base-universal/Dockerfile: must contain the BU apt-get block
#   - All other flavours: must use "FROM ghcr.io/wyattau/runner-images/base-universal:" as base
#   - No flavour should duplicate BU packages (git, curl, jq, make, build-essential, etc.)
#
# Exit 1 on any violation.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FLAVOUR_DIRS=("$REPO_ROOT"/images/*/)

errors=0

for dir in "${FLAVOUR_DIRS[@]}"; do
  dockerfile="$dir/Dockerfile"
  name=$(basename "$dir")

  if [ ! -f "$dockerfile" ]; then
    echo "SKIP: $name (no Dockerfile)"
    continue
  fi

  if [ "$name" = "shared" ]; then
    continue
  fi

  if [ "$name" = "base-universal" ]; then
    # Verify base-universal contains the BU apt-get block
    if grep -q 'apt-get install.*git=' "$dockerfile" && \
       grep -q 'apt-get install.*curl=' "$dockerfile" && \
       grep -q 'apt-get install.*jq=' "$dockerfile" && \
       grep -q 'apt-get install.*make=' "$dockerfile" && \
       grep -q 'apt-get install.*build-essential' "$dockerfile"; then
      echo "PASS: $name (contains BU apt-get block)"
    else
      echo "FAIL: $name -- missing BU apt-get block"
      errors=$((errors + 1))
    fi

    # Verify USER/WORKDIR/ENTRYPOINT are NOT set (children need root)
    if grep -qE '^\s*USER\s+runner' "$dockerfile"; then
      echo "FAIL: $name -- must not set USER runner (children need root access)"
      errors=$((errors + 1))
    else
      echo "PASS: $name (no USER directive — children can run as root)"
    fi
  else
    # Verify child image uses FROM base-universal
    if grep -qE 'FROM\s+ghcr\.io/wyattau/runner-images/base-universal:' "$dockerfile"; then
      echo "PASS: $name (inherits from base-universal)"
    else
      echo "FAIL: $name -- must use 'FROM ghcr.io/wyattau/runner-images/base-universal:...' as base"
      errors=$((errors + 1))
    fi

    # Verify child image does NOT contain BU packages
    bu_packages=("git=" "git-lfs=" "openssh-client=" "jq=" "yq=" "wget=" "zstd=" "tree=")
    found_bu=0
    for pkg in "${bu_packages[@]}"; do
      if grep -q "apt-get install.*${pkg}" "$dockerfile"; then
        echo "FAIL: $name -- duplicates BU package: $pkg"
        found_bu=1
      fi
    done
    if [ "$found_bu" -eq 0 ]; then
      echo "PASS: $name (no BU package duplication)"
    else
      errors=$((errors + 1))
    fi

    # Verify child image sets USER runner at the end
    if grep -qE '^\s*USER\s+runner' "$dockerfile"; then
      echo "PASS: $name (sets USER runner)"
    else
      echo "FAIL: $name -- must set 'USER runner' at the end"
      errors=$((errors + 1))
    fi
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "ERROR: $errors consistency violation(s) found."
  echo ""
  echo "B1 Architecture Rules:"
  echo "  - base-universal: contains BU apt-get block, NO USER/WORKDIR/ENTRYPOINT"
  echo "  - All other flavours: FROM base-universal, no BU duplication, sets USER runner"
  exit 1
fi

echo ""
echo "All flavours conform to B1 layered architecture."
exit 0
