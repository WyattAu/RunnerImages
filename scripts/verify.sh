#!/bin/bash
set -euo pipefail

# Verification script for Forgejo Actions runner images
# Usage: ./scripts/verify.sh <flavour>

FLAVOUR=${1:?"Usage: $0 <flavour>"}
REPO="ghcr.io/wyattau/runner-images"
VERSION=$(cat "images/$FLAVOUR/VERSION" | tr -d '[:space:]')
IMAGE="$REPO/$FLAVOUR:$VERSION"

echo "=== Verifying $FLAVOUR:$VERSION ==="
echo ""

PASS=0
FAIL=0

run() {
  docker run --rm "$IMAGE" -c "$1"
}

check() {
  local name=$1
  local result=$2
  if [ "$result" = "PASS" ]; then
    echo "  ✓ $name"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $name: $result"
    FAIL=$((FAIL + 1))
  fi
}

# --- User checks ---
echo "User:"
USER_ID=$(run "id runner")
check "UID=1000" "$(echo "$USER_ID" | grep -q 'uid=1000' && echo PASS || echo "uid != 1000: $USER_ID")"
check "GID=1000" "$(echo "$USER_ID" | grep -q 'gid=1000' && echo PASS || echo "gid != 1000: $USER_ID")"
check "HOME=/home/runner" "$(run "echo \$HOME" | grep -q '/home/runner' && echo PASS || echo 'wrong HOME')"
check "LANG=C.UTF-8" "$(run "echo \$LANG" | grep -q 'C.UTF-8' && echo PASS || echo 'wrong LANG')"

# --- Shell checks ---
echo "Shell:"
check "bash available" "$(run "bash --version" | grep -q '5\.' && echo PASS || echo 'not found')"

# --- VCS checks ---
echo "VCS:"
check "git available" "$(run "git --version" | grep -q '2\.' && echo PASS || echo 'not found')"
check "git-lfs available" "$(run "git lfs version" | grep -q 'git-lfs' && echo PASS || echo 'not found')"
check "ssh available" "$(run "ssh -V" 2>&1 | grep -q 'OpenSSH' && echo PASS || echo 'not found')"

# --- Build checks ---
echo "Build:"
check "make available" "$(run "make --version" | grep -q 'GNU Make' && echo PASS || echo 'not found')"
check "gcc available" "$(run "gcc --version" | grep -q 'gcc' && echo PASS || echo 'not found')"
check "g++ available" "$(run "g++ --version" | grep -q 'g++' && echo PASS || echo 'not found')"

# --- Data checks ---
echo "Data:"
check "jq available" "$(run "jq --version" | grep -q 'jq' && echo PASS || echo 'not found')"

# --- HTTP checks ---
echo "HTTP:"
check "curl available" "$(run "curl --version" | grep -q 'curl' && echo PASS || echo 'not found')"
check "wget available" "$(run "wget --version" | grep -q 'GNU Wget' && echo PASS || echo 'not found')"

# --- Archive checks ---
echo "Archive:"
check "zip available" "$(run "zip --version" | grep -q 'Copyright' && echo PASS || echo 'not found')"
check "unzip available" "$(run "unzip -v" | grep -q 'UnZip' && echo PASS || echo 'not found')"
check "zstd available" "$(run "zstd --version" | grep -qi 'zstd\|zstandard' && echo PASS || echo 'not found')"

# --- Crypto checks ---
echo "Crypto:"
check "openssl available" "$(run "openssl version" | grep -q 'OpenSSL' && echo PASS || echo 'not found')"

# --- Docker checks (ubuntu-specific) ---
echo "Docker:"
check "docker CLI available" "$(run "docker --version" | grep -q 'Docker' && echo PASS || echo 'not found')"

# --- Runtime checks ---
echo "Runtime:"
check "apt-get update works" "$(run "sudo apt-get update >/dev/null 2>&1" >/dev/null 2>&1 && echo PASS || echo 'failed')"
check "can install packages" "$(run "sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y --no-install-recommends htop >/dev/null 2>&1 && sudo rm -rf /var/lib/apt/lists/*" >/dev/null 2>&1 && echo PASS || echo 'failed')"

# --- Layer count ---
echo "Layers:"
LAYERS=$(docker inspect --format '{{len .RootFS.Layers}}' "$IMAGE")
check "Layer count <= 4" "$( [ "$LAYERS" -le 4 ] && echo PASS || echo "$LAYERS layers (max 4)")"

# --- Size checks ---
echo "Size:"
COMPRESSED=$(docker save "$IMAGE" | gzip -9 | wc -c | awk '{printf "%.0f", $1/1024/1024}')
UNCOMPRESSED=$(docker inspect --format '{{.Size}}' "$IMAGE" | awk '{printf "%.0f", $1/1024/1024}')
check "Compressed <= 225MB" "$( [ "$COMPRESSED" -le 225 ] && echo PASS || echo "${COMPRESSED}MB")"
check "Uncompressed <= 630MB" "$( [ "$UNCOMPRESSED" -le 630 ] && echo PASS || echo "${UNCOMPRESSED}MB")"

# --- Summary ---
echo ""
echo "=== Results ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "VERIFICATION FAILED"
  exit 1
fi

echo ""
echo "VERIFICATION PASSED"
