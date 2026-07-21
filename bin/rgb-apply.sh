#!/usr/bin/env bash
# Case, cooler and RAM lighting: purple flow matching the driftwm Quantum Realm.
#
# Full write-up, including how to change any of this yourself:
#   ~/Documents/Brain dump/RGB lighting on Linux - NZXT case, Kraken and RAM.md
#
# Everything below is load-bearing and was found the hard way. Read the doc
# before changing a value.
#
#   sync, not led1/led2   The Smart Device V2 firmware ignored per-channel
#                         writes until the kernel driver was out of the way.
#                         `sync` is the combined bitmask (led1=0x01, led2=0x02,
#                         sync=0x03) and always works; per-channel works too now
#                         and is used to tint the fans separately.
#   saturated colours     LEDs emit, screens reflect. The DMS accent #BC9AFA is
#                         a pale lavender and renders as dim dirty white on an
#                         LED. Keep the green channel at or near 0 or the purple
#                         washes out.
#   fading, not marquee   covering-marquee walks LED by LED and reads as a
#                         periodic rotation; fading crossfades the whole channel
#                         and actually looks like the realm drifting.
#   no kernel driver      nzxt_smart2 / nzxt_kraken3 must stay unloaded, see the
#                         blacklist in /etc/modprobe.d/nzxt-liquidctl.conf.
#   OpenRGB stays off NZXT  It crashes on these devices and its crash-protection
#                         then disables the detectors; it also resets them to a
#                         flat colour. Its NZXT detectors are disabled in
#                         ~/.config/OpenRGB/OpenRGB.json. OpenRGB drives the RAM
#                         only.
set -uo pipefail

# Deep violets, green channel 0 so nothing washes to white.
STRIP=(4b0082 6600cc 8000ff 9d00ff 6a00d4)
# The AER RGB 2 fans render warmer than the strip, so they get less red.
FANS=(2b00b3 3d00e6 5000ff 6600ff 3a00cc)
# RAM LEDs are much brighter than the case; these are the strip values at ~50%.
RAM_COLORS="${RGB_RAM_COLORS:-330066,4e0080}"
SPEED="${RGB_SPEED:-slower}"

LOG="$HOME/.local/log/rgb-apply.log"
mkdir -p "$(dirname "$LOG")"
log() { echo "$(date '+%Y-%m-%d %H:%M') $*" >>"$LOG"; }

fail=0

# At boot the USB controllers can enumerate after the user session is up. Wait
# for both to appear (up to ~30s) instead of racing them and silently doing
# nothing; systemd restarts the unit if this still fails.
for _ in $(seq 30); do
  found=$(liquidctl list 2>/dev/null | grep -ci "nzxt")
  [ "${found:-0}" -ge 2 ] && break
  sleep 1
done
if [ "${found:-0}" -lt 2 ]; then
  log "NZXT devices not present after 30s (found ${found:-0}), giving up"
  exit 1
fi

# Detects the LED accessories. Without this after a cold boot the device
# reports none and every colour command is silently a no-op.
liquidctl --match "smart device" initialize >/dev/null 2>&1
liquidctl --match kraken initialize >/dev/null 2>&1

liquidctl --match "smart device" set led1 color fading "${STRIP[@]}" \
  --speed "$SPEED" >/dev/null 2>&1 || fail=1
liquidctl --match "smart device" set led2 color fading "${FANS[@]}" \
  --speed "$SPEED" >/dev/null 2>&1 || fail=1
liquidctl --match kraken set sync color fading "${STRIP[@]}" \
  --speed "$SPEED" >/dev/null 2>&1 || fail=1

# Both RGB DIMMs. Only 2 of the 4 sticks have LEDs: the 2x8GB CMW kit is
# Vengeance RGB Pro, the 2x16GB CMK kit is LPX and has none.
if command -v openrgb >/dev/null 2>&1; then
  for i in 0 1; do
    openrgb --noautoconnect --device "$i" --mode "Color Shift" \
      --color "$RAM_COLORS" >/dev/null 2>&1 || fail=1
  done
fi

# Static per-LED highlight on the fan rings, applied last so it wins over the
# fading set above. RGB_SHINE=0 leaves the fans flowing instead.
if [ "${RGB_SHINE:-1}" = 1 ] && [ -x "$HOME/.local/bin/rgb-shine.sh" ]; then
  "$HOME/.local/bin/rgb-shine.sh" >/dev/null 2>&1 || fail=1
fi

if [ "$fail" -eq 0 ]; then
  log "applied realm purple flow"
  exit 0
fi
# Non-zero so systemd's Restart=on-failure gets another go at it.
log "applied with errors"
exit 1
