#!/usr/bin/env bash
# Regenerate the driftwm canvas starmap variants from NASA source.
# Produces pyramidal TIFFs that driftwm streams as LOD chunks (tile mode).
#
# Source: NASA SVS Deep Star Maps 2020 (public domain), 16k galactic EXR.
# Variants: _pyr (neutral), _vivid (saturated), _purple (the active one).
#
# Run niced: the 16k float pipeline eats cores. VIPS_CONCURRENCY caps threads.
set -euo pipefail

DIR="$HOME/Pictures/Wallpapers"
EXR="$DIR/starmap_2020_16k_gal.exr"
URL="https://svs.gsfc.nasa.gov/vis/a000000/a004800/a004851/starmap_2020_16k_gal.exr"
W="$(mktemp -d "$HOME/.cache/starmap-work.XXXXXX")"
trap 'rm -rf "$W"' EXIT
export VIPS_CONCURRENCY="${VIPS_CONCURRENCY:-3}"

mkdir -p "$DIR"
[ -f "$EXR" ] || curl -fSL "$URL" -o "$EXR"

run() { nice -n 19 ionice -c3 vips "$@"; }

# Shared front of the pipeline: RGB, exposure lift, display gamma.
run extract_band "$EXR" "$W/rgb.v" 0 --n 3
run linear "$W/rgb.v" "$W/exp.v" 1.65 0
run math2_const "$W/exp.v" "$W/gam.v" pow 0.4545

pyramid() { # $1 input.v  $2 output.tif
  run linear "$1" "$W/lin.v" 255 0
  run cast "$W/lin.v" "$W/u8.v" uchar
  run tiffsave "$W/u8.v" "$2" --tile --pyramid --compression deflate \
    --tile-width 256 --tile-height 256
}

# Neutral
pyramid "$W/gam.v" "$DIR/starmap_2020_16k_gal_pyr.tif"

# Vivid: saturation 1.45 around Rec.709 luminance
printf '3 3\n1.3543 -0.3218 -0.0325\n-0.0957 1.1282 -0.0325\n-0.0957 -0.3218 1.4175\n' > "$W/sat145.mat"
run recomb "$W/gam.v" "$W/sat.v" "$W/sat145.mat"
pyramid "$W/sat.v" "$DIR/starmap_2020_16k_gal_vivid.tif"

# Purple: R/B boost with G pull, then saturation 1.35
printf '3 3\n1.2837 -0.2478 -0.0250\n-0.0737 0.8688 -0.0250\n-0.0737 -0.2478 1.0915\n' > "$W/sat135.mat"
run linear "$W/gam.v" "$W/tint.v" "1.12 0.70 1.38" "0 0 0"
run recomb "$W/tint.v" "$W/psat.v" "$W/sat135.mat"
pyramid "$W/psat.v" "$DIR/starmap_2020_16k_gal_purple.tif"

echo "done: $DIR/starmap_2020_16k_gal_{pyr,vivid,purple}.tif"
