#!/usr/bin/env bash
# Package a compiled Freebuff binary + tree-sitter.wasm as a Termux .deb.
set -euo pipefail
umask 022

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BINARY="${1:?usage: package-deb.sh <binary> <tree-sitter.wasm> <version> <revision> <outdir>}"
WASM="${2:?usage: package-deb.sh <binary> <tree-sitter.wasm> <version> <revision> <outdir>}"
VERSION="${3:?usage: package-deb.sh <binary> <tree-sitter.wasm> <version> <revision> <outdir>}"
REVISION="${4:?usage: package-deb.sh <binary> <tree-sitter.wasm> <version> <revision> <outdir>}"
OUTDIR="${5:?usage: package-deb.sh <binary> <tree-sitter.wasm> <version> <revision> <outdir>}"

test -x "$BINARY" || { echo "error: $BINARY is not executable" >&2; exit 1; }
test -f "$WASM" || { echo "error: $WASM is missing" >&2; exit 1; }

command -v dpkg-deb >/dev/null || { echo "error: dpkg-deb is required" >&2; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/freebuff-deb.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

ROOT="$WORK/root"
TERMUX_PREFIX="${TERMUX_PREFIX:-/data/data/com.termux/files/usr}"
PREFIX_ROOT="$ROOT$TERMUX_PREFIX"
mkdir -p \
  "$ROOT/DEBIAN" \
  "$PREFIX_ROOT/bin" \
  "$PREFIX_ROOT/lib/freebuff" \
  "$PREFIX_ROOT/share/doc/freebuff"

# mktemp gives the staging root mode 0700; dpkg-deb requires the control
# directory to be group/world traversable.
chmod 0755 "$WORK" "$ROOT" "$ROOT/DEBIAN"

install -m 0755 "$BINARY" "$PREFIX_ROOT/lib/freebuff/freebuff"
install -m 0644 "$WASM" "$PREFIX_ROOT/lib/freebuff/tree-sitter.wasm"
ln -s ../lib/freebuff/freebuff "$PREFIX_ROOT/bin/freebuff"

{
  echo "Freebuff for Termux/Android"
  echo "Port: https://github.com/emonbudc/freebuff-bionic"
  echo "Upstream: https://github.com/CodebuffAI/freebuff"
  echo
  cat "$KIT_ROOT/LICENSE"
  echo
  cat "$KIT_ROOT/NOTICE"
} > "$PREFIX_ROOT/share/doc/freebuff/copyright"

INSTALLED_SIZE="$(du -sk "$PREFIX_ROOT" | cut -f1)"

cat > "$ROOT/DEBIAN/control" <<EOF
Package: freebuff
Version: ${VERSION}-${REVISION}
Architecture: aarch64
Maintainer: emonbudc <221848809+emonbudc@users.noreply.github.com>
Installed-Size: ${INSTALLED_SIZE}
Depends: git, ripgrep, termux-tools, ca-certificates
Section: utils
Priority: optional
Homepage: https://github.com/emonbudc/freebuff-bionic
Description: Freebuff terminal coding agent for Termux/Android
 Native Bionic aarch64 build of the Freebuff CLI. Includes the
 tree-sitter.wasm sibling required by the compiled executable.
EOF

mkdir -p "$OUTDIR"
DEB="$OUTDIR/freebuff_${VERSION}-${REVISION}_aarch64.deb"
dpkg-deb --build --root-owner-group -Zxz "$ROOT" "$DEB" >/dev/null

dpkg-deb -c "$DEB" > "$WORK/contents"
grep -q '\./data/data/com.termux/files/usr/lib/freebuff/freebuff$' "$WORK/contents" || {
  echo "error: package payload is not rooted under the Termux prefix" >&2
  exit 1
}

(
  cd "$OUTDIR"
  sha256sum "$(basename "$DEB")" > "$(basename "$DEB").sha256"
)

dpkg-deb --info "$DEB"
echo
dpkg-deb --contents "$DEB"
echo
ls -lh "$DEB" "$DEB.sha256"
