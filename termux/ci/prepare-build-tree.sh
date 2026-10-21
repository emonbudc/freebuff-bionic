#!/usr/bin/env bash
# Create a fresh upstream tree at the pinned commit and apply the Termux port.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:?usage: prepare-build-tree.sh <destination>}"

bash "$KIT_ROOT/termux/ci/fetch-upstream.sh" "$DEST" >/dev/null

while IFS= read -r patch; do
  [ -n "$patch" ] || continue
  echo "→ applying $patch"
  git -C "$DEST" apply --whitespace=nowarn "$KIT_ROOT/termux/patches/$patch"
done < "$KIT_ROOT/termux/patches/series"

cp "$KIT_ROOT/termux/bun.lock" "$DEST/bun.lock"

grep -q 'npm:@androidtui/core@0.5.1' "$DEST/cli/package.json" || {
  echo "error: AndroidTUI alias missing after patching" >&2
  exit 1
}
grep -q "'android-arm64'" "$DEST/cli/scripts/build-binary.ts" || {
  echo "error: Android build target missing after patching" >&2
  exit 1
}

echo "→ build tree ready: $DEST"
