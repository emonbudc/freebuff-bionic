#!/data/data/com.termux/files/usr/bin/bash
# Install the native Freebuff .deb on Termux/Android aarch64.
set -euo pipefail

REPO="emonbudc/freebuff-bionic"

case "$(uname -m)" in
  aarch64|arm64) ;;
  *) echo "error: only aarch64 Termux is supported" >&2; exit 1 ;;
esac

if [ "${1:-}" = "" ]; then
  echo "→ resolving latest release"
  TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep -m1 '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')"
  [ -n "$TAG" ] || { echo "error: could not resolve the latest release" >&2; exit 1; }
else
  TAG="${1#v}"
  case "$TAG" in
    *-*) ;;
    *) TAG="$TAG-1" ;;
  esac
fi

DEB="freebuff_${TAG}_aarch64.deb"
URL="https://github.com/$REPO/releases/download/v${TAG}/${DEB}"
TMPDIR="${TMPDIR:-${PREFIX:-/data/data/com.termux/files/usr}/tmp}"
TMP="$TMPDIR/$DEB"
mkdir -p "$TMPDIR"
trap 'rm -f "$TMP" "$TMP.sha256"' EXIT

echo "→ downloading Freebuff $TAG"
curl -fL --retry 3 -o "$TMP" "$URL"
curl -fL --retry 3 -o "$TMP.sha256" "$URL.sha256"
echo "→ verifying checksum"
(
  cd "$TMPDIR"
  sha256sum -c "$(basename "$TMP").sha256"
)
echo "→ installing"
dpkg -i "$TMP"

echo
freebuff --version
echo "Done. Run 'freebuff' inside a project directory."
