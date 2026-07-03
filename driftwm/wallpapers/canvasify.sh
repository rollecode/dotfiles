#!/usr/bin/env bash
# canvasify: turn any wallpaper into a driftwm canvas background.
# GPU-upscales the image with Real-ESRGAN, then bakes a pyramidal TIFF that
# driftwm streams as LOD chunks (tile mode), so it stays sharp under zoom.
#
# Usage: canvasify.sh <image-file-or-URL> [scale] [model]
#   scale: 2, 3 or 4 (default 4)
#   model: realesrgan-x4plus (default, photographic/painterly)
#          realesrgan-x4plus-anime (flat/illustrated art, crisper lines)
#
# Output: ~/Pictures/Wallpapers/canvas/<name>_x<scale>_pyr.tif
# plus the ready-to-paste [background] config snippet.
#
# Note: the upscale runs on the GPU and can hiccup a live compositor for a
# minute on big images. Tile size 256 keeps VRAM modest.
set -euo pipefail

SRC="${1:?usage: canvasify.sh <image-or-url> [scale] [model]}"
SCALE="${2:-4}"
MODEL="${3:-realesrgan-x4plus}"
OUTDIR="$HOME/Pictures/Wallpapers/canvas"
W="$(mktemp -d "$HOME/.cache/canvasify.XXXXXX")"
trap 'rm -rf "$W"' EXIT
mkdir -p "$OUTDIR"

case "$SRC" in
  http://*|https://*)
    IN="$W/input"
    curl -fSL "$SRC" -o "$IN"
    ;;
  *) IN="$SRC" ;;
esac
NAME="$(basename "${SRC%%\?*}")"
NAME="${NAME%.*}"

nice -n 19 realesrgan-ncnn-vulkan -i "$IN" -o "$W/up.png" -s "$SCALE" -n "$MODEL" -t 256

OUT="$OUTDIR/${NAME}_x${SCALE}_pyr.tif"
VIPS_CONCURRENCY="${VIPS_CONCURRENCY:-3}" nice -n 19 vips tiffsave "$W/up.png" "$OUT" \
  --tile --pyramid --bigtiff --compression deflate --tile-width 256 --tile-height 256

echo "done: $OUT ($(vipsheader -f width "$OUT")x$(vipsheader -f height "$OUT"))"
echo
echo "[background]"
echo "type = \"tile\""
echo "path = \"${OUT/#$HOME/~}\""
