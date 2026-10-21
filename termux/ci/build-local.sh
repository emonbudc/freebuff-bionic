#!/usr/bin/env bash
# Build Freebuff natively on this Termux installation.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_ROOT="${BUILD_ROOT:-$KIT_ROOT/.build/freebuff}"
DIST="${DIST:-$KIT_ROOT/dist}"

for cmd in bun git python3 dpkg-deb rg; do
  command -v "$cmd" >/dev/null || {
    echo "error: missing '$cmd'. Install it with pkg before building." >&2
    exit 1
  }
done

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "error: this build currently targets aarch64 only" >&2; exit 1 ;;
esac

VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["freebuff"]["version"])' "$KIT_ROOT/versions.json")"
REVISION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["freebuff"]["debRevision"])' "$KIT_ROOT/versions.json")"

bash "$KIT_ROOT/termux/ci/prepare-build-tree.sh" "$BUILD_ROOT"
bash "$KIT_ROOT/termux/ci/build-tree.sh" "$BUILD_ROOT" "$BUILD_ROOT/artifacts"
bash "$KIT_ROOT/termux/ci/package-deb.sh" \
  "$BUILD_ROOT/artifacts/freebuff" \
  "$BUILD_ROOT/artifacts/tree-sitter.wasm" \
  "$VERSION" "$REVISION" "$DIST"

echo
echo "Artifacts:"
ls -lh "$DIST"
