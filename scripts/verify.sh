#!/bin/bash
set -euo pipefail

# Verification script for Forgejo Actions runner images
# Usage: ./scripts/verify.sh <flavour>
# Checks are flavour-aware: only tests packages that should be present

FLAVOUR="${1:?"Usage: $0 <flavour>"}"
REPO="${REPO:-ghcr.io/wyattau/runner-images}"

# --- Input validation ---
if [ ! -d "images/$FLAVOUR" ]; then
  echo "ERROR: Unknown flavour '$FLAVOUR'"
  echo "Available: $(ls images/)"
  exit 1
fi

if [ ! -f "images/$FLAVOUR/VERSION" ]; then
  echo "ERROR: images/$FLAVOUR/VERSION not found"
  exit 1
fi

if [ ! -f "images/$FLAVOUR/Dockerfile" ]; then
  echo "ERROR: images/$FLAVOUR/Dockerfile not found"
  exit 1
fi

command -v docker >/dev/null 2>&1 || { echo "ERROR: docker not found in PATH"; exit 1; }

VERSION=$(tr -d '[:space:]' < "images/$FLAVOUR/VERSION")

# Semver validation
if ! echo "$VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
  echo "ERROR: VERSION '$VERSION' is not valid semver (expected MAJOR.MINOR.PATCH)"
  exit 1
fi

IMAGE="$REPO/$FLAVOUR:$VERSION"

# Check image exists
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
  echo "ERROR: Image $IMAGE not found. Build it first: ./scripts/build.sh $FLAVOUR"
  exit 1
fi

echo "=== Verifying $FLAVOUR:$VERSION ==="
echo ""

PASS=0
FAIL=0

# Print summary on exit (handles set -e early termination)
print_summary() {
  echo ""
  echo "=== Results ==="
  echo "Passed: $PASS"
  echo "Failed: $FAIL"
  if [ "${FAIL:-0}" -gt 0 ]; then
    echo ""
    echo "VERIFICATION FAILED"
    exit 1
  fi
  echo ""
  echo "VERIFICATION PASSED"
  exit 0
}
trap print_summary EXIT

# run: execute command inside the container via bash -c
run() {
  docker run --rm "$IMAGE" -c "$1"
}

check() {
  local name="$1"
  local result="$2"
  if [ "$result" = "PASS" ]; then
    echo "  [PASS] $name"
    PASS=$((PASS + 1))
  else
    echo "  [FAIL] $name: $result"
    FAIL=$((FAIL + 1))
  fi
}

# ---------------------------------------------------------------------------
# Flavour capability map
# Format: capability_name:test_command:flavours_that_have_it
# ---------------------------------------------------------------------------
HAS_DOCKER=false
HAS_NODE=false
HAS_PYTHON=false
HAS_SUDO=false
HAS_PKG_CONFIG=false
HAS_PING=false

case "$FLAVOUR" in
  base-universal) ;;
  ubuntu)         HAS_DOCKER=true; HAS_SUDO=true; HAS_PKG_CONFIG=true; HAS_PING=true ;;
  node)           HAS_NODE=true; HAS_SUDO=true ;;
  python)         HAS_PYTHON=true; HAS_SUDO=true ;;
  heavy)          HAS_DOCKER=true; HAS_NODE=true; HAS_PYTHON=true; HAS_SUDO=true; HAS_PKG_CONFIG=true; HAS_PING=true ;;
  flutter)        HAS_DOCKER=true; HAS_NODE=true; HAS_SUDO=true ;;
  *)              echo "WARN: Unknown flavour '$FLAVOUR', running BU-only checks" ;;
esac

# --- User checks ---
echo "User:"
USER_ID=$(run "id runner")
check "UID=1000" "$(echo "$USER_ID" | grep -q 'uid=1000' && echo PASS || echo "uid != 1000: $USER_ID")"
check "GID=1000" "$(echo "$USER_ID" | grep -q 'gid=1000' && echo PASS || echo "gid != 1000: $USER_ID")"
check "HOME=/home/runner" "$(run "echo \$HOME" | grep -q '/home/runner' && echo PASS || echo 'wrong HOME')"
check "whoami is runner" "$(run "whoami" | grep -q 'runner' && echo PASS || echo 'wrong user')"

# --- Environment checks (UP3) ---
echo "Environment:"
check "LANG=C.UTF-8" "$(run "echo \$LANG" | grep -q 'C.UTF-8' && echo PASS || echo 'wrong LANG')"
check "LANGUAGE=C:en" "$(run "echo \$LANGUAGE" | grep -q 'C:en' && echo PASS || echo 'wrong LANGUAGE')"
check "LC_ALL=C.UTF-8" "$(run "echo \$LC_ALL" | grep -q 'C.UTF-8' && echo PASS || echo 'wrong LC_ALL')"
check "DEBIAN_FRONTEND=noninteractive" "$(run "echo \$DEBIAN_FRONTEND" | grep -q 'noninteractive' && echo PASS || echo 'wrong DEBIAN_FRONTEND')"
check "PATH includes .local/bin" "$(run "echo \$PATH" | grep -q '/home/runner/.local/bin' && echo PASS || echo 'missing .local/bin in PATH')"

# --- Shell checks ---
echo "Shell:"
check "bash available" "$(run "bash --version" | grep -q '5\.' && echo PASS || echo 'not found')"

# --- VCS checks ---
echo "VCS:"
check "git available" "$(run "git --version" | grep -q '2\.' && echo PASS || echo 'not found')"
check "git-lfs available" "$(run "git lfs version" | grep -q 'git-lfs' && echo PASS || echo 'not found')"
check "ssh available" "$(run "ssh -V" 2>&1 | grep -q 'OpenSSH' && echo PASS || echo 'not found')"
check "ssh-keygen available" "$(run "which ssh-keygen" | grep -q 'ssh-keygen' && echo PASS || echo 'not found')"

# --- Build checks (BU) ---
echo "Build:"
check "make available" "$(run "make --version" | grep -q 'GNU Make' && echo PASS || echo 'not found')"
check "gcc available" "$(run "gcc --version" | grep -q 'gcc' && echo PASS || echo 'not found')"
check "g++ available" "$(run "g++ --version" | grep -q 'g++' && echo PASS || echo 'not found')"

# --- Data checks ---
echo "Data:"
check "jq available" "$(run "jq --version" | grep -q 'jq' && echo PASS || echo 'not found')"
check "yq available" "$(run "yq --version" | grep -q 'yq' && echo PASS || echo 'not found')"

# --- HTTP checks ---
echo "HTTP:"
check "curl available" "$(run "curl --version" | grep -q 'curl' && echo PASS || echo 'not found')"
check "wget available" "$(run "wget --version" | grep -q 'GNU Wget' && echo PASS || echo 'not found')"

# --- Archive checks ---
echo "Archive:"
check "zip available" "$(run "zip --version" | grep -q 'Copyright' && echo PASS || echo 'not found')"
check "unzip available" "$(run "unzip -v" | grep -q 'UnZip' && echo PASS || echo 'not found')"
check "zstd available" "$(run "zstd --version" | grep -qi 'zstd\|zstandard' && echo PASS || echo 'not found')"
check "tar available" "$(run "tar --version" | grep -q 'tar' && echo PASS || echo 'not found')"
check "gzip available" "$(run "gzip --version" | grep -q 'gzip' && echo PASS || echo 'not found')"

# --- Crypto checks ---
echo "Crypto:"
check "openssl available" "$(run "openssl version" | grep -q 'OpenSSL' && echo PASS || echo 'not found')"

# --- System checks ---
echo "System:"
check "diff available" "$(run "diff --version" | grep -q 'diffutils' && echo PASS || echo 'not found')"
check "patch available" "$(run "patch --version" | grep -q 'patch' && echo PASS || echo 'not found')"
check "file available" "$(run "file --version" | grep -q 'file' && echo PASS || echo 'not found')"
check "tree available" "$(run "tree --version" | grep -q 'tree' && echo PASS || echo 'not found')"

# --- Docker checks (flavour-conditional) ---
echo "Docker:"
if [ "$HAS_DOCKER" = true ]; then
  check "docker CLI available" "$(run "docker --version" | grep -q 'Docker' && echo PASS || echo 'not found')"
else
  check "docker NOT present" "$( (run "docker --version" 2>&1 || true) | grep -qi 'not found\|no such' && echo PASS || echo 'docker should not be present')"
fi

# --- Node.js checks (flavour-conditional) ---
echo "Node.js:"
if [ "$HAS_NODE" = true ]; then
  check "node available" "$(run "node --version" | grep -q 'v22\.' && echo PASS || echo 'not found')"
  check "npm available" "$(run "npm --version" | grep -q '.' && echo PASS || echo 'not found')"
  check "yarn available" "$(run "yarn --version" | grep -q '.' && echo PASS || echo 'not found')"
  check "pnpm available" "$(run "pnpm --version" | grep -q '.' && echo PASS || echo 'not found')"
else
  check "node NOT present" "$( (run "node --version" 2>&1 || true) | grep -qi 'not found\|no such' && echo PASS || echo 'node should not be present')"
fi

# --- Python checks (flavour-conditional) ---
echo "Python:"
if [ "$HAS_PYTHON" = true ]; then
  check "python3 available" "$(run "python3 --version" | grep -q '3\.' && echo PASS || echo 'not found')"
  check "pip3 available" "$(run "pip3 --version" | grep -q 'pip' && echo PASS || echo 'not found')"
  check "venv available" "$(run "python3 -m venv --help" | grep -q 'venv' && echo PASS || echo 'not found')"
else
  check "pip3 NOT present" "$( (run "pip3 --version" 2>&1 || true) | grep -qi 'not found\|no such' && echo PASS || echo 'pip3 should not be present')"
fi

# --- Extra tools (flavour-conditional) ---
echo "Extras:"
if [ "$HAS_PKG_CONFIG" = true ]; then
  check "pkg-config available" "$(run "pkg-config --version" | grep -q '.' && echo PASS || echo 'not found')"
fi
if [ "$HAS_SUDO" = true ]; then
  check "sudo available" "$(run "sudo --version" | grep -q 'Sudo' && echo PASS || echo 'not found')"
else
  check "sudo NOT present" "$( (run "sudo --version" 2>&1 || true) | grep -qi 'not found\|no such' && echo PASS || echo 'sudo should not be present')"
fi
if [ "$HAS_PING" = true ]; then
  check "ping available" "$(run "which ping" | grep -q 'ping' && echo PASS || echo 'not found')"
fi

# --- Runtime checks ---
echo "Runtime:"
if [ "$HAS_SUDO" = true ]; then
  check "apt-get update works" "$(run "sudo apt-get update >/dev/null 2>&1" >/dev/null 2>&1 && echo PASS || echo 'failed')"
  check "can install packages" "$(run "sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y --no-install-recommends htop >/dev/null 2>&1 && sudo rm -rf /var/lib/apt/lists/*" >/dev/null 2>&1 && echo PASS || echo 'failed')"
else
  # base-universal has no sudo; run runtime checks as root
  check "apt-get update works" "$(docker run --user root --rm "$IMAGE" -c "apt-get update >/dev/null 2>&1" >/dev/null 2>&1 && echo PASS || echo 'failed')"
  check "can install packages" "$(docker run --user root --rm "$IMAGE" -c "apt-get update >/dev/null 2>&1 && apt-get install -y --no-install-recommends htop >/dev/null 2>&1 && rm -rf /var/lib/apt/lists/*" >/dev/null 2>&1 && echo PASS || echo 'failed')"
fi

# --- Entrypoint check (C9) ---
echo "Entrypoint:"
ENTRYPOINT=$(docker inspect --format '{{.Config.Entrypoint}}' "$IMAGE")
check "Entrypoint is /bin/bash" "$( [ "$ENTRYPOINT" = "[/bin/bash]" ] && echo PASS || echo "got: $ENTRYPOINT")"

# --- Architecture check (C10) ---
echo "Architecture:"
ARCH=$(docker inspect --format '{{.Architecture}}' "$IMAGE")
check "Architecture is amd64" "$( [ "$ARCH" = "amd64" ] && echo PASS || echo "got: $ARCH")"

# --- OCI Label checks (UP8) ---
echo "Labels:"
LABEL_TITLE=$(docker inspect --format '{{index .Config.Labels "org.opencontainers.image.title"}}' "$IMAGE" 2>/dev/null || echo "")
check "OCI title label" "$( [ -n "$LABEL_TITLE" ] && echo PASS || echo 'missing org.opencontainers.image.title')"
LABEL_VERSION=$(docker inspect --format '{{index .Config.Labels "org.opencontainers.image.version"}}' "$IMAGE" 2>/dev/null || echo "")
check "OCI version label" "$( [ -n "$LABEL_VERSION" ] && echo PASS || echo 'missing org.opencontainers.image.version')"
LABEL_SOURCE=$(docker inspect --format '{{index .Config.Labels "org.opencontainers.image.source"}}' "$IMAGE" 2>/dev/null || echo "")
check "OCI source label" "$( [ -n "$LABEL_SOURCE" ] && echo PASS || echo 'missing org.opencontainers.image.source')"

# --- Security checks (S5.2) ---
echo "Security:"
if [ "$HAS_SUDO" = true ]; then
  SUID_COUNT=$(docker run --rm "$IMAGE" find / -perm /4000 -type f 2>/dev/null | grep -cv '^/usr/bin/sudo$' || true)
else
  SUID_COUNT=$(docker run --rm "$IMAGE" find / -perm /4000 -type f 2>/dev/null | wc -l || true)
fi
SUID_COUNT=$(echo "$SUID_COUNT" | tr -d '[:space:]')
check "No unexpected SUID binaries" "$( [ "${SUID_COUNT:-0}" -eq 0 ] && echo PASS || echo "${SUID_COUNT} unexpected SUID binaries found")"
WW_COUNT=$(docker run --user root --rm "$IMAGE" find / -perm -002 -type f 2>/dev/null | wc -l || true)
WW_COUNT=$(echo "$WW_COUNT" | tr -d '[:space:]')
check "No world-writable files" "$( [ "${WW_COUNT:-0}" -eq 0 ] && echo PASS || echo "${WW_COUNT} world-writable files found")"

# --- Layer count ---
echo "Layers:"
LAYERS=$(docker inspect --format '{{len .RootFS.Layers}}' "$IMAGE")
check "Layer count <= 4" "$( [ "$LAYERS" -le 4 ] && echo PASS || echo "$LAYERS layers (max 4)")"

# --- Size checks ---
echo "Size:"
COMPRESSED_BYTES=$(docker save "$IMAGE" | gzip -6 | wc -c)
COMPRESSED_MB=$((COMPRESSED_BYTES / 1024 / 1024))
UNCOMPRESSED_BYTES=$(docker inspect --format '{{.Size}}' "$IMAGE")
UNCOMPRESSED_MB=$((UNCOMPRESSED_BYTES / 1024 / 1024))

case "$FLAVOUR" in
  heavy|flutter) COMP_BUDGET=350; UNCOMP_BUDGET=900 ;;
  ubuntu)        COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
  node)          COMP_BUDGET=275; UNCOMP_BUDGET=700 ;;
  python)        COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
  base-universal) COMP_BUDGET=200; UNCOMP_BUDGET=530 ;;
  *)             COMP_BUDGET=225; UNCOMP_BUDGET=630 ;;
esac

check "Compressed <= ${COMP_BUDGET}MB" "$( [ "$COMPRESSED_MB" -le "$COMP_BUDGET" ] && echo PASS || echo "${COMPRESSED_MB}MB (budget: ${COMP_BUDGET}MB)")"
check "Uncompressed <= ${UNCOMP_BUDGET}MB" "$( [ "$UNCOMPRESSED_MB" -le "$UNCOMP_BUDGET" ] && echo PASS || echo "${UNCOMPRESSED_MB}MB (budget: ${UNCOMP_BUDGET}MB)")"
