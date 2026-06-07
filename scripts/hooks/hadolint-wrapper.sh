#!/usr/bin/env bash
# Wrapper for hadolint that skips gracefully if not installed
set -euo pipefail

if ! command -v hadolint >/dev/null 2>&1; then
  echo "hadolint not found, skipping Dockerfile lint"
  exit 0
fi

hadolint "$@"
