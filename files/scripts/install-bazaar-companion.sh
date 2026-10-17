#!/usr/bin/bash
# Install the Bazaar companion GNOME Shell extension system-wide.
#
# The companion is not published on extensions.gnome.org; upstream ships a
# prebuilt bundle in its repository. Fetch a pinned revision, extract it into
# the system extension directory, and compile its schemas.
set -euo pipefail

REF="551ab812fda96e76fecc29a06f2adc993dd4e041"
UUID="bazaar-integration@kolunmi.github.io"
URL="https://github.com/bazaar-org/bazaar-companion/raw/${REF}/${UUID}.shell-extension.zip"
DEST="/usr/share/gnome-shell/extensions/${UUID}"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$URL" -o "$tmp/companion.zip"
rm -rf "$DEST"
mkdir -p "$DEST"
unzip -q "$tmp/companion.zip" -d "$DEST"

# The bundle may wrap its files in a top-level directory; flatten so that
# metadata.json sits directly under $DEST.
if [ ! -f "$DEST/metadata.json" ]; then
  inner="$(find "$DEST" -maxdepth 2 -name metadata.json -printf '%h\n' | head -n1)"
  if [ -n "$inner" ] && [ "$inner" != "$DEST" ]; then
    cp -a "$inner/." "$DEST/"
  fi
fi

[ -f "$DEST/metadata.json" ] || {
  echo "bazaar-companion: metadata.json missing after extraction" >&2
  exit 1
}

if [ -d "$DEST/schemas" ]; then
  glib-compile-schemas "$DEST/schemas"
fi
