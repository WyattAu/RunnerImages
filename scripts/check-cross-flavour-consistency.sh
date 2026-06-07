#!/usr/bin/env bash
# check-cross-flavour-consistency.sh
# Verifies that shared version-sensitive values are identical across Dockerfiles:
#   - Node.js version and SHA256 (node, heavy)
#   - docker-ce-cli version (ubuntu, heavy)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Extract NODE_VERSION from each Dockerfile that has it
NODE_DOCKERFILES=()
for f in "$REPO_ROOT"/images/*/Dockerfile; do
  if grep -q "ARG NODE_VERSION=" "$f"; then
    NODE_DOCKERFILES+=("$f")
  fi
done

if [ ${#NODE_DOCKERFILES[@]} -lt 2 ]; then
  echo "INFO: Only ${#NODE_DOCKERFILES[@]} Dockerfile(s) use Node.js, consistency check skipped."
  exit 0
fi

errors=0

# Check NODE_VERSION consistency
versions=()
for f in "${NODE_DOCKERFILES[@]}"; do
  name=$(basename "$(dirname "$f")")
  ver=$(grep -oP 'ARG NODE_VERSION=\K[^\s]+' "$f")
  versions+=("$name=$ver")
done

first_ver="${versions[0]#*=}"
for entry in "${versions[@]}"; do
  name="${entry%=*}"
  ver="${entry#*=}"
  if [ "$ver" != "$first_ver" ]; then
    echo "FAIL: $name has NODE_VERSION=$ver, expected $first_ver"
    errors=$((errors + 1))
  fi
done

# Check NODE_SHA256 consistency
shas=()
for f in "${NODE_DOCKERFILES[@]}"; do
  name=$(basename "$(dirname "$f")")
  sha=$(grep -oP 'NODE_SHA256=\K[a-f0-9]+' "$f")
  shas+=("$name=$sha")
done

first_sha="${shas[0]#*=}"
for entry in "${shas[@]}"; do
  name="${entry%=*}"
  sha="${entry#*=}"
  if [ "$sha" != "$first_sha" ]; then
    echo "FAIL: $name has NODE_SHA256=$sha, expected $first_sha"
    errors=$((errors + 1))
  fi
done

if [ "$errors" -gt 0 ]; then
  echo ""
  echo "ERROR: Node.js version or SHA mismatch between Dockerfiles."
  exit 1
fi

echo "PASS: Node.js version ($first_ver) and SHA consistent across ${#NODE_DOCKERFILES[@]} Dockerfiles."

# Also check docker-ce-cli version consistency
DOCKER_DOCKERFILES=()
for f in "$REPO_ROOT"/images/*/Dockerfile; do
  if grep -q "docker-ce-cli=" "$f"; then
    DOCKER_DOCKERFILES+=("$f")
  fi
done

if [ ${#DOCKER_DOCKERFILES[@]} -ge 2 ]; then
  docker_vers=()
  for f in "${DOCKER_DOCKERFILES[@]}"; do
    name=$(basename "$(dirname "$f")")
    ver=$(grep -oP 'docker-ce-cli=\K[^\s\\]+' "$f")
    docker_vers+=("$name=$ver")
  done

  first_docker_ver="${docker_vers[0]#*=}"
  docker_errors=0
  for entry in "${docker_vers[@]}"; do
    name="${entry%=*}"
    ver="${entry#*=}"
    if [ "$ver" != "$first_docker_ver" ]; then
      echo "FAIL: $name has docker-ce-cli=$ver, expected $first_docker_ver"
      docker_errors=$((docker_errors + 1))
    fi
  done

  if [ "$docker_errors" -gt 0 ]; then
    echo "ERROR: docker-ce-cli version mismatch between Dockerfiles."
    exit 1
  fi

  echo "PASS: docker-ce-cli version ($first_docker_ver) consistent across ${#DOCKER_DOCKERFILES[@]} Dockerfiles."
fi

exit 0
