#!/usr/bin/bash
# Stage the Adwaita-for-Steam skin sources into the image.
#
# Adwaita-for-Steam is a CSS skin for the native Steam client. It is per-user
# (it writes into ~/.steam/steam), so the image only ships the sources; the
# user unit silver-hour-steam-theme.service runs install.py once against the
# user's Steam directory after its first launch.
#
# The release is pinned for reproducible builds; Renovate bumps TAG (see
# renovate.json).
set -euo pipefail

TAG="3.17"
DEST="/usr/share/silver-hour/adwaita-for-steam"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://github.com/tkashkin/Adwaita-for-Steam/archive/refs/tags/${TAG}.tar.gz" \
  -o "$tmp/adwaita.tar.gz"

tar -xzf "$tmp/adwaita.tar.gz" -C "$tmp"
src="$(find "$tmp" -maxdepth 1 -type d -name 'Adwaita-for-Steam-*' | head -n1)"
[ -n "$src" ] || { echo "adwaita-for-steam: source tree not found (${TAG})" >&2; exit 1; }

mkdir -p "$DEST"
cp -a "$src/." "$DEST/"
[ -f "$DEST/install.py" ] || { echo "adwaita-for-steam: install.py missing" >&2; exit 1; }
find "$DEST" -name '*.pyc' -delete 2>/dev/null || true
