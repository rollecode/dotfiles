#!/usr/bin/env bash
# Experimental: a bright "shine" highlight on one side of each fan ring.
#
# Revert with:  ~/.local/bin/rgb-apply.sh
#
# Uses liquidctl's super-fixed mode, the only one that takes a colour per LED
# (up to 40). Each AER RGB 2 140 mm ring has 8 LEDs, two fans on led2 = 16.
# Trade-off: super-fixed is static, so the fans stop animating while this is on.
# The strip, pump head and RAM keep whatever rgb-apply.sh last set.
#
# The LED numbered 0 is wherever the fan's cable enters the ring, which depends
# on how each fan is mounted, so the bright spot may not start on the right.
# Rotate it until it looks right:
#
#   SHINE_PEAK=0 ~/.local/bin/rgb-shine.sh    # try 0..7
#   SHINE_PEAK=6 SHINE_WIDTH=1.5 ~/.local/bin/rgb-shine.sh
#   SHINE_HI=ffffff ~/.local/bin/rgb-shine.sh # white hotspot instead of pale purple
set -uo pipefail

LEDS_PER_FAN=8
FANS=2
PEAK="${SHINE_PEAK:-3}"      # centre LED of the highlight, 0..7
WIDTH="${SHINE_WIDTH:-1.2}"  # falloff span in LEDs; bigger = softer, wider
BASE="${SHINE_BASE:-2b00b3}" # the dim rest of the ring
HI="${SHINE_HI:-cc66ff}"     # bright spot; keep green low or it looks greenish-white

colors=$(python3 - "$LEDS_PER_FAN" "$FANS" "$PEAK" "$WIDTH" "$BASE" "$HI" <<'PY'
import sys
n, fans, peak, width = int(sys.argv[1]), int(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
base = tuple(int(sys.argv[5][i:i+2], 16) for i in (0, 2, 4))
hi   = tuple(int(sys.argv[6][i:i+2], 16) for i in (0, 2, 4))

out = []
for _ in range(fans):
    for i in range(n):
        # shortest distance around the ring, so the highlight wraps smoothly
        d = min(abs(i - peak), n - abs(i - peak))
        t = max(0.0, 1.0 - (d / width) ** 2)
        out.append("".join("%02x" % round(b + (h - b) * t) for b, h in zip(base, hi)))
print(" ".join(out))
PY
)

# shellcheck disable=SC2086
liquidctl --match "smart device" set led2 color super-fixed $colors
rc=$?
echo "peak=$PEAK width=$WIDTH base=$BASE hi=$HI"
echo "$colors" | tr ' ' '\n' | head -8 | nl -ba | sed 's/^/  fan LED /'
exit $rc
