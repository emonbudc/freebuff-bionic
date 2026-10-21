#!/usr/bin/env bash
# Run the Termux aarch64 build container from an ARM64 GitHub runner.
set -euo pipefail

: "${GITHUB_WORKSPACE:?GITHUB_WORKSPACE must be set}"

OUT_HOST="$(cd "$GITHUB_WORKSPACE/.." && pwd)/freebuff-out"
rm -rf "$OUT_HOST"
mkdir -p "$OUT_HOST"
chmod 0777 "$OUT_HOST"

docker run --rm \
  -v "$GITHUB_WORKSPACE:/workspace:ro" \
  -v "$OUT_HOST:/out" \
  -w /workspace \
  termux/termux-docker:aarch64 \
  bash /workspace/termux/ci/build-in-container.sh

echo "=== host artifacts ==="
ls -lh "$OUT_HOST"
