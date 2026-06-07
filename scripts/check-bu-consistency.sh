#!/usr/bin/env bash
# check-bu-consistency.sh
# Verifies that the BU layer block is identical across all flavour Dockerfiles.
# Uses the canonical fragment at images/shared/bu.fragment.
# Exit 1 on any mismatch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRAGMENT="$REPO_ROOT/images/shared/bu.fragment"
FLAVOUR_DIRS=("$REPO_ROOT"/images/*)

if [ ! -f "$FRAGMENT" ]; then
  echo "ERROR: BU fragment not found at $FRAGMENT"
  exit 1
fi

# Extract canonical BU block from fragment (between BU-START and BU-END)
canonical=$(sed -n '/^# BU-START$/,/^# BU-END$/p' "$FRAGMENT" | sed '1d;$d')

errors=0
for dir in "${FLAVOUR_DIRS[@]}"; do
  dockerfile="$dir/Dockerfile"
  name=$(basename "$dir")

  if [ "$name" = "shared" ]; then
    echo "SKIP: $name (no Dockerfile)"
    continue
  fi

  if [ ! -f "$dockerfile" ]; then
    echo "SKIP: $name (no Dockerfile)"
    continue
  fi

  # Extract BU block from Dockerfile (FROM base ... through the last || true line)
  # The BU block starts with "FROM ubuntu:24.04@sha256:..." and ends with the last find || true
  actual=$(sed -n "/^FROM ubuntu:24\.04@sha256:.*AS base$/,/find \/ -perm -002.*|| true/p" "$dockerfile")

  if [ -z "$actual" ]; then
    echo "FAIL: $name -- BU block not found"
    errors=$((errors + 1))
    continue
  fi

  # Compare: strip comment-only lines and blank lines, keep only active instructions
  canon_block=$(echo "$canonical" | grep -v '^#' | grep -v '^$')
  actual_block=$(echo "$actual" | grep -v '^#' | grep -v '^$')

  if [ "$canon_block" = "$actual_block" ]; then
    echo "PASS: $name (variant: bu)"
  else
    echo "FAIL: $name -- BU block (bu variant) differs from canonical fragment"
    diff <(echo "$canon_block") <(echo "$actual_block") || true
    errors=$((errors + 1))
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "ERROR: $errors flavour(s) have divergent BU blocks."
  echo "Fix: Update the Dockerfile(s) to match the canonical fragment:"
  echo "  - images/shared/bu.fragment"
  exit 1
fi

echo ""
echo "All flavours match their canonical BU fragment."
exit 0
