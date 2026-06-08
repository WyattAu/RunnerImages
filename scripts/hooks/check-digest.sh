#!/bin/bash
# Pre-commit hook: verify base image digest pinning in Dockerfiles
# B1: Child images using ghcr.io/wyattau/runner-images/base-universal are exempt
set -euo pipefail

for f in "$@"; do
  # Skip check for B1 child images (they inherit from our own base-universal)
  if grep -qP 'FROM\s+ghcr\.io/wyattau/runner-images/base-universal:' "$f"; then
    echo "OK: $f (B1 layered — inherits from base-universal)"
    continue
  fi
  if ! grep -qP 'FROM ubuntu:24.04@sha256:' "$f"; then
    echo "ERROR: $f must pin base image by SHA256 digest"
    exit 1
  fi
done
