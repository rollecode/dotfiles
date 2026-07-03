#!/usr/bin/env bash
# wallset: set a fixed (viewport-glued) driftwm wallpaper from a file or URL.
# Center-crops to the 3440x1440 aspect when needed, updates config.toml,
# and driftwm hot-reloads it. For tiling canvas backgrounds use canvasify.sh.
#
# Usage: wallset.sh <image-file-or-URL>
set -euo pipefail

SRC="${1:?usage: wallset.sh <image-or-url>}"
OUTDIR="$HOME/Pictures/Wallpapers/fixed"
CONF="$HOME/.config/driftwm/config.toml"
W="$(mktemp -d "$HOME/.cache/wallset.XXXXXX")"
trap 'rm -rf "$W"' EXIT
mkdir -p "$OUTDIR"

case "$SRC" in
  http://*|https://*) IN="$W/input"; curl -fSL "$SRC" -o "$IN" ;;
  *) IN="$SRC" ;;
esac
NAME="$(basename "${SRC%%\?*}")"; NAME="${NAME%.*}"

WPX="$(vipsheader -f width "$IN")"
HPX="$(vipsheader -f height "$IN")"
TARGET_W=3440; TARGET_H=1440

# Center-crop to the viewport aspect (no stretch distortion).
CROP_H=$(( WPX * TARGET_H / TARGET_W ))
if [ "$CROP_H" -le "$HPX" ]; then
  CROP_W=$WPX
else
  CROP_H=$HPX
  CROP_W=$(( HPX * TARGET_W / TARGET_H ))
fi
LEFT=$(( (WPX - CROP_W) / 2 ))
TOP=$(( (HPX - CROP_H) / 2 ))

OUT="$OUTDIR/${NAME}_uw.jpg"
vips crop "$IN" "$OUT" "$LEFT" "$TOP" "$CROP_W" "$CROP_H"

# Point the [background] section at it (type wallpaper), keep the rest.
python3 - "$OUT" "$CONF" <<'EOF'
import re, sys, pathlib
out, conf = sys.argv[1], pathlib.Path(sys.argv[2])
home = str(pathlib.Path.home())
out = out.replace(home, "~")
t = conf.read_text()
t = re.sub(r'(\[background\]\n)(?:[^\[]*?)(\ncache_budget_mb|\n\n\[)',
           f'\\1type = "wallpaper"\npath = "{out}"\\2', t, count=1, flags=re.S)
conf.write_text(t)
print(f"wallpaper set: {out}")
EOF
