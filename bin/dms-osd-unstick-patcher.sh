#!/usr/bin/env bash
#
# DMS OSD Unstick Patcher
#
# Fixes the year-old "no OSD popup after hyprlock unlock" bug. The volume,
# brightness etc. controls keep working, the chime plays, the bar widget
# updates - only the popup OSD silently never appears. A `systemctl --user
# restart dms.service` clears it, but that also tears down every
# spotlight-spawned app in DMS's cgroup, so the restart workaround is worse
# than the bug.
#
# Root cause: DankOSD.show() early-returns when shouldBeVisible is true.
# During a hyprlock cycle, hyprlock's exclusive input grab leaves DankOSD
# in a mismatched state - shouldBeVisible stays true, but the underlying
# layer surface was already cleared (or hideTimer keeps restarting because
# mouseArea.containsMouse latched true under the lock surface). Every
# subsequent show() then hits the guard and silently does nothing.
#
# This patch adds an unstick prologue to show(): if shouldBeVisible is set
# but the surface is not actually visible, reset both flags and the timers
# before falling through to the normal show path.
#
# Patches one file:
#   /usr/share/quickshell/dms/Widgets/DankOSD.qml
#
# Idempotent: grep-checks the unstick marker and no-ops if already applied.
# Backs up the original to <file>.osd-unstick.backup on first apply. Safe to
# re-run after a dms-shell package upgrade clobbers the patched file.
#
# The patched QML only takes effect on the next DMS process spawn (next
# Hyprland session, or whenever DMS is otherwise restarted). It does not
# affect a running DMS - so applying this script never disturbs your
# current session.

set -euo pipefail

DMS_DIR="/usr/share/quickshell/dms"
OSD_FILE="$DMS_DIR/Widgets/DankOSD.qml"

LOG_FILE="$HOME/.local/share/dms-osd-unstick-patcher.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

mkdir -p "$(dirname "$LOG_FILE")"
log() { printf '[%s] %s\n' "$TIMESTAMP" "$*" | tee -a "$LOG_FILE"; }
die() { log "$*"; exit "${2:-1}"; }

[ -f "$OSD_FILE" ] || die "ERROR: missing $OSD_FILE - is dms-shell installed?"

if grep -q 'shouldBeVisible && !visible' "$OSD_FILE"; then
    log "DankOSD.qml already patched (unstick guard present); nothing to do"
    exit 0
fi

# Anchor on `        if (shouldBeVisible) {` - this exact line appears only
# in DankOSD.show()'s early-return guard. Insert the unstick prologue
# immediately before it.
if ! grep -q '^        if (shouldBeVisible) {$' "$OSD_FILE"; then
    die "ERROR: anchor line not found - DankOSD.show() shape changed upstream?" 2
fi

log "Patching DankOSD.qml: add stuck-state unstick prologue to show()"
[ -f "$OSD_FILE.osd-unstick.backup" ] || sudo cp "$OSD_FILE" "$OSD_FILE.osd-unstick.backup"

sudo sed -i 's|^        if (shouldBeVisible) {$|        // unstick: hyprlock occlusion can leave shouldBeVisible=true with the\n        // underlying surface already gone, so every subsequent show() silently\n        // early-returns. Reset both flags and timers first when mismatched.\n        if (shouldBeVisible \&\& !visible) {\n            shouldBeVisible = false;\n            hideTimer.stop();\n            closeTimer.stop();\n        }\n        if (shouldBeVisible) {|' "$OSD_FILE"

if grep -q 'shouldBeVisible && !visible' "$OSD_FILE"; then
    log "  ok"
    log "Patch applied. Takes effect on the next DMS process spawn (next clean Hyprland session)."
    log "No need to restart dms.service - the running DMS keeps its current in-memory QML until it dies."
else
    log "  FAILED - restoring backup"
    sudo cp "$OSD_FILE.osd-unstick.backup" "$OSD_FILE"
    exit 2
fi
