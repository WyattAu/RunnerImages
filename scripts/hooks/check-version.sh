#!/bin/bash
# Pre-commit hook: verify VERSION files contain valid semver
set -euo pipefail

for f in "$@"; do
  v=$(tr -d '[:space:]' < "$f")
  if ! echo "$v" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
    echo "ERROR: $f must contain valid semver (got: $v)"
    exit 1
  fi
done
