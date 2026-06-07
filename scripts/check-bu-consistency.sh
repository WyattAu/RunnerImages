#!/usr/bin/env bash
# check-bu-consistency.sh
# Verifies that the BU layer block is identical across all flavour Dockerfiles.
# Supports two BU variants:
#   - bu.fragment (with strip) — used by most flavours
#   - bu-no-strip.fragment (without strip) — used by strip-sensitive flavours
#
# Each Dockerfile is checked against BOTH fragments; it must match exactly one.
# A Dockerfile declares its variant via a comment on line 2:
#   "# BU variant: bu-no-strip"  →  checks against bu-no-strip.fragment
#   (no comment or any other value)  →  checks against bu.fragment
#
# Exit 1 on any mismatch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FRAGMENT_STRIP="$REPO_ROOT/images/shared/bu.fragment"
FRAGMENT_NOSTRIP="$REPO_ROOT/images/shared/bu-no-strip.fragment"
FLAVOUR_DIRS=("$REPO_ROOT"/images/*/)

if [ ! -f "$FRAGMENT_STRIP" ]; then
  echo "ERROR: BU fragment not found at $FRAGMENT_STRIP"
  exit 1
fi
if [ ! -f "$FRAGMENT_NOSTRIP" ]; then
  echo "ERROR: BU-no-strip fragment not found at $FRAGMENT_NOSTRIP"
  exit 1
fi

# Extract canonical BU blocks from fragments
canonical_strip=$(sed -n '/^# BU-START$/,/^# BU-END$/p' "$FRAGMENT_STRIP")
canonical_nostrip=$(sed -n '/^# BU-NO-STRIP-START$/,/^# BU-NO-STRIP-END$/p' "$FRAGMENT_NOSTRIP")

errors=0
for dir in "${FLAVOUR_DIRS[@]}"; do
  dockerfile="$dir/Dockerfile"
  name=$(basename "$dir")

  if [ ! -f "$dockerfile" ]; then
    echo "SKIP: $name (no Dockerfile)"
    continue
  fi

  # Determine which BU variant this Dockerfile uses
  # Check line 2 for "# BU variant: bu-no-strip"
  variant="bu"
  if head -5 "$dockerfile" | grep -q '# BU variant: bu-no-strip'; then
    variant="bu-no-strip"
  fi

  # Select canonical block based on variant
  if [ "$variant" = "bu-no-strip" ]; then
    canonical="$canonical_nostrip"
    end_pattern='&& find \/ -perm -002.*|| true'
  else
    canonical="$canonical_strip"
    end_pattern='&& find \/ -perm -002.*|| true'
  fi

  # Extract BU block from Dockerfile
  actual=$(sed -n "/^FROM ubuntu:24\.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54 AS base$/,/${end_pattern}/p" "$dockerfile")

  if [ -z "$actual" ]; then
    echo "FAIL: $name -- BU block not found"
    errors=$((errors + 1))
    continue
  fi

  # Compare: strip comment-only lines and blank lines, keep only active instructions
  canon_block=$(echo "$canonical" | sed -n '/^FROM ubuntu/,/|| true$/p' | grep -v '^#' | grep -v '^$')
  actual_block=$(echo "$actual" | grep -v '^#' | grep -v '^$')

  if [ "$canon_block" = "$actual_block" ]; then
    echo "PASS: $name (variant: $variant)"
  else
    echo "FAIL: $name -- BU block ($variant variant) differs from canonical fragment"
    diff <(echo "$canon_block") <(echo "$actual_block") || true
    errors=$((errors + 1))
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "ERROR: $errors flavour(s) have divergent BU blocks."
  echo "Fix: Update the Dockerfile(s) to match the correct fragment:"
  echo "  - images/shared/bu.fragment (standard)"
  echo "  - images/shared/bu-no-strip.fragment (strip-sensitive)"
  echo "Declare variant: add '# BU variant: bu-no-strip' on line 2 of the Dockerfile"
  exit 1
fi

echo ""
echo "All flavours match their canonical BU fragment."
exit 0
