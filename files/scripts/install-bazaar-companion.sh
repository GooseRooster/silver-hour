#!/usr/bin/bash
# Install the Bazaar companion GNOME Shell extension system-wide.
#
# The companion is not published on extensions.gnome.org. Upstream ships source
# (with the current shell-version) under src/, but its committed prebuilt zip
# can lag behind the source and declare an older GNOME version. Build from the
# pinned source revision instead (this mirrors upstream's build.sh, minus the
# packing step, since a system install is just the unpacked extension tree).
set -euo pipefail

REF="551ab812fda96e76fecc29a06f2adc993dd4e041"
UUID="bazaar-integration@kolunmi.github.io"
DEST="/usr/share/gnome-shell/extensions/${UUID}"
TARBALL="https://github.com/bazaar-org/bazaar-companion/archive/${REF}.tar.gz"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "$TARBALL" -o "$tmp/companion.tar.gz"
tar -xzf "$tmp/companion.tar.gz" -C "$tmp"
src="$(find "$tmp" -maxdepth 1 -type d -name 'bazaar-companion-*' | head -n1)"
[ -n "$src" ] || { echo "bazaar-companion: source tree not found" >&2; exit 1; }

rm -rf "$DEST"
mkdir -p "$DEST"
cp -a "$src/src/." "$DEST/"
[ -f "$DEST/metadata.json" ] || { echo "bazaar-companion: metadata.json missing" >&2; exit 1; }

if [ -d "$DEST/schemas" ]; then
  glib-compile-schemas "$DEST/schemas"
fi
