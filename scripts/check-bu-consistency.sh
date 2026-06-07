#!/usr/bin/env bash
# check-bu-consistency.sh
# Verifies that the BU layer block is identical across all flavour Dockerfiles.
# Exit 1 on any mismatch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRAGMENT="$REPO_ROOT/images/shared/bu.fragment"
FLAVOUR_DIRS=("$REPO_ROOT"/images/*/)

if [ ! -f "$FRAGMENT" ]; then
  echo "ERROR: BU fragment not found at $FRAGMENT"
  exit 1
fi

# Extract canonical BU block from fragment (between BU-START and BU-END inclusive)
canonical=$(sed -n '/^# BU-START$/,/^# BU-END$/p' "$FRAGMENT")

errors=0
for dir in "${FLAVOUR_DIRS[@]}"; do
  dockerfile="$dir/Dockerfile"
  name=$(basename "$dir")

  if [ ! -f "$dockerfile" ]; then
    echo "SKIP: $name (no Dockerfile)"
    continue
  fi

  # Extract BU block from this Dockerfile (FROM base AS bu-base ... through the thinning line)
  # The BU block starts at "FROM ubuntu:24.04@sha256:..." and ends after the last find command
  # We match from "FROM ubuntu:24.04@sha256:" through the line ending "|| true" after o-w
  actual=$(sed -n '/^FROM ubuntu:24\.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS base$/,/^ && find \/ -perm -002.*|| true$/p' "$dockerfile")

  if [ -z "$actual" ]; then
    echo "FAIL: $name -- BU block not found"
    errors=$((errors + 1))
    continue
  fi

  # Compare: strip comment-only lines and blank lines, keep only active instructions
  canon_block=$(echo "$canonical" | sed -n '/^FROM ubuntu/,/|| true$/p' | grep -v '^#' | grep -v '^$')
  actual_block=$(echo "$actual" | grep -v '^#' | grep -v '^$')

  if [ "$canon_block" = "$actual_block" ]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name -- BU block differs from canonical fragment"
    diff <(echo "$canon_block") <(echo "$actual_block") || true
    errors=$((errors + 1))
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "ERROR: $errors flavour(s) have divergent BU blocks."
  echo "Fix: Update the Dockerfile(s) to match images/shared/bu.fragment"
  exit 1
fi

echo ""
echo "All flavours match the canonical BU fragment."
exit 0
