#!/usr/bin/env bash
# Install dependencies and compile Freebuff inside a prepared build tree.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TREE="${1:?usage: build-tree.sh <build-tree> <artifact-dir>}"
OUT="${2:?usage: build-tree.sh <build-tree> <artifact-dir>}"

VERSION="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["freebuff"]["version"])' "$KIT_ROOT/versions.json")"

# shellcheck disable=SC1091
. "$KIT_ROOT/termux/build-env.sh"

cd "$TREE"
bun install --frozen-lockfile

FREEBUFF_MODE=true bun cli/scripts/build-binary.ts freebuff "$VERSION"

mkdir -p "$OUT"
install -m 0755 cli/bin/freebuff "$OUT/freebuff"
install -m 0644 cli/bin/tree-sitter.wasm "$OUT/tree-sitter.wasm"

chmod +x "$OUT/freebuff"
"$OUT/freebuff" --version

(
  cd "$OUT"
  sha256sum freebuff tree-sitter.wasm > SHA256SUMS
)

echo "→ built Freebuff $VERSION in $OUT"
