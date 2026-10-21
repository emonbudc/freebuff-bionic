#!/data/data/com.termux/files/usr/bin/bash
# Runs inside termux/termux-docker:aarch64.
#
# /workspace = this build kit (read-only)
# /out       = writable artifact directory
set -euo pipefail

KIT_ROOT="${KIT_ROOT:-/workspace}"
OUT="${OUT:-/out}"
BUILD_ROOT="${BUILD_ROOT:-$HOME/freebuff}"

if [ -f "$OUT/build-env.sh" ]; then
  # shellcheck disable=SC1091
  . "$OUT/build-env.sh"
fi

echo "=== Freebuff build on $(uname -m) ==="
echo "PREFIX=${PREFIX:-unset} HOME=$HOME"

export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y git python curl dpkg xz-utils

VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["freebuff"]["version"])' "$KIT_ROOT/versions.json")"
REVISION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["freebuff"]["debRevision"])' "$KIT_ROOT/versions.json")"
BUN_TERMUX_VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["bunTermux"]["version"])' "$KIT_ROOT/versions.json")"
BUN_DEB="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["bunTermux"]["asset"])' "$KIT_ROOT/versions.json")"

echo "=== Freebuff $VERSION ($REVISION) ==="

BUN_TMP_DEB="$(mktemp)"
echo "→ installing bun-termux $BUN_TERMUX_VERSION"
curl -fsSL -o "$BUN_TMP_DEB" \
  "https://github.com/bd-loser/bun-termux/releases/download/v${BUN_TERMUX_VERSION}/${BUN_DEB}"
dpkg -i "$BUN_TMP_DEB"
rm -f "$BUN_TMP_DEB"

WANT_BUN="${BUN_TERMUX_VERSION%%-patched}"
GOT_BUN="$(bun --version)"
if [ "$GOT_BUN" != "$WANT_BUN" ]; then
  echo "error: expected bun $WANT_BUN, got $GOT_BUN" >&2
  exit 1
fi

mkdir -p "$OUT"
chmod 0777 "$OUT" 2>/dev/null || true

bash "$KIT_ROOT/termux/ci/prepare-build-tree.sh" "$BUILD_ROOT"
bash "$KIT_ROOT/termux/ci/build-tree.sh" "$BUILD_ROOT" "$BUILD_ROOT/artifacts"
bash "$KIT_ROOT/termux/ci/package-deb.sh" \
  "$BUILD_ROOT/artifacts/freebuff" \
  "$BUILD_ROOT/artifacts/tree-sitter.wasm" \
  "$VERSION" "$REVISION" "$OUT"

echo "=== artifacts ==="
ls -lh "$OUT"
