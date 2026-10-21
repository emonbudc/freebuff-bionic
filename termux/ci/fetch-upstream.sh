#!/usr/bin/env bash
# Fetch the exact upstream Freebuff snapshot pinned in versions.json.
set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:?usage: fetch-upstream.sh <destination>}"

REPO="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstream"]["repository"])' "$KIT_ROOT/versions.json")"
COMMIT="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["upstream"]["commit"])' "$KIT_ROOT/versions.json")"

rm -rf "$DEST"
mkdir -p "$DEST"
git -C "$DEST" init -q
git -C "$DEST" remote add origin "$REPO"

if ! git -C "$DEST" fetch --depth 1 origin "$COMMIT" 2>/dev/null; then
  echo "Direct SHA fetch failed; trying the default branch" >&2
  git -C "$DEST" fetch --depth 1 origin main
fi
git -C "$DEST" checkout -q --detach FETCH_HEAD

ACTUAL="$(git -C "$DEST" rev-parse HEAD)"
if [ "$ACTUAL" != "$COMMIT" ]; then
  echo "error: upstream HEAD is $ACTUAL, expected $COMMIT" >&2
  exit 1
fi

echo "$DEST"
