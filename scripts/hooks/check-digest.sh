#!/bin/bash
# Pre-commit hook: verify base image digest pinning in Dockerfiles
set -euo pipefail

for f in "$@"; do
  if ! grep -qP 'FROM ubuntu:24.04@sha256:' "$f"; then
    echo "ERROR: $f must pin base image by SHA256 digest"
    exit 1
  fi
done
