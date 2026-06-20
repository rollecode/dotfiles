#!/usr/bin/env bash
#
# DMS Fade-to-Lock Patcher
# Backports upstream DankMaterialShell PR #2653 onto v1.4.6's installed QML.
#
# Without the patch: with a custom locker (SettingsData.customPowerActionLock,
# e.g. hyprlock), the FadeToLockWindow black overlay stays up after the
# external locker exits. The desktop becomes unusable and any OSDs (volume
# HUD, etc) render under the dead overlay.
#
# PR #2653 (merged 2026-06-16, commit ca1a45c) adds a dismissFadeToLock
# signal path so the overlay is torn down right after the custom locker is
# spawned. Upstream master has it; tagged v1.4.6 (what cachyos/extra ships
# as dms-shell{,-hyprland} 1.4.6) does not.
#
# This script re-applies the patch onto the installed files. Idempotent:
# each step grep-checks for the patched marker and no-ops if present. Run
# again after a `dms-shell` package upgrade. Retire once dms-shell ships
# >= v1.4.7 / v1.5 with PR #2653 included.

set -euo pipefail

DMS_DIR="/usr/share/quickshell/dms"
FADE_FILE="$DMS_DIR/Modules/Lock/FadeToLockWindow.qml"
IDLE_FILE="$DMS_DIR/Services/IdleService.qml"
LOCK_FILE="$DMS_DIR/Modules/Lock/Lock.qml"
SHELL_FILE="$DMS_DIR/DMSShell.qml"

LOG_FILE="$HOME/.local/share/dms-fade-lock-patcher.log"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

mkdir -p "$(dirname "$LOG_FILE")"
log() { printf '[%s] %s\n' "$TIMESTAMP" "$*" | tee -a "$LOG_FILE"; }
die() { log "$*"; exit "${2:-1}"; }

for f in "$FADE_FILE" "$IDLE_FILE" "$LOCK_FILE" "$SHELL_FILE"; do
    [ -f "$f" ] || die "ERROR: missing $f - is dms-shell installed?"
done

command -v perl >/dev/null || die "ERROR: perl not found, required for DMSShell.qml patch"

CHANGES_MADE=false

# --- 1. FadeToLockWindow.qml: add function dismiss() ----------------------
# dismiss() differs from cancelFade() in that it does not emit fadeCancelled,
# because the external locker took over - this is not a user-initiated abort.
if ! grep -q '^    function dismiss()' "$FADE_FILE"; then
    log "Patching FadeToLockWindow.qml: add function dismiss()"
    [ -f "$FADE_FILE.backup" ] || sudo cp "$FADE_FILE" "$FADE_FILE.backup"

    sudo sed -i 's|^    MouseArea {$|    function dismiss() {\n        fadeSeq.stop();\n        fadeOverlay.opacity = 0.0;\n        active = false;\n    }\n\n    MouseArea {|' "$FADE_FILE"

    if grep -q '^    function dismiss()' "$FADE_FILE"; then
        log "  ok"
        CHANGES_MADE=true
    else
        log "  FAILED - restoring backup"
        sudo cp "$FADE_FILE.backup" "$FADE_FILE"
        exit 2
    fi
else
    log "FadeToLockWindow.qml already patched (dismiss() present); skip"
fi

# --- 2. IdleService.qml: add signal dismissFadeToLock ---------------------
if ! grep -q '^    signal dismissFadeToLock$' "$IDLE_FILE"; then
    log "Patching IdleService.qml: add signal dismissFadeToLock"
    [ -f "$IDLE_FILE.backup" ] || sudo cp "$IDLE_FILE" "$IDLE_FILE.backup"

    sudo sed -i 's|^    signal cancelFadeToLock$|    signal cancelFadeToLock\n    signal dismissFadeToLock|' "$IDLE_FILE"

    if grep -q '^    signal dismissFadeToLock$' "$IDLE_FILE"; then
        log "  ok"
        CHANGES_MADE=true
    else
        log "  FAILED - restoring backup"
        sudo cp "$IDLE_FILE.backup" "$IDLE_FILE"
        exit 2
    fi
else
    log "IdleService.qml already patched (dismissFadeToLock signal present); skip"
fi

# --- 3. Lock.qml: emit dismissFadeToLock after spawning external locker ---
if ! grep -q 'IdleService.dismissFadeToLock();' "$LOCK_FILE"; then
    log "Patching Lock.qml: emit dismissFadeToLock() after execDetached"
    [ -f "$LOCK_FILE.backup" ] || sudo cp "$LOCK_FILE" "$LOCK_FILE.backup"

    # Insert immediately after the execDetached line in the custom-lock branch
    sudo sed -i 's|^\(.*Quickshell\.execDetached.*customPowerActionLock.*\)$|\1\n            IdleService.dismissFadeToLock();|' "$LOCK_FILE"

    if grep -q 'IdleService.dismissFadeToLock();' "$LOCK_FILE"; then
        log "  ok"
        CHANGES_MADE=true
    else
        log "  FAILED - restoring backup"
        sudo cp "$LOCK_FILE.backup" "$LOCK_FILE"
        exit 2
    fi
else
    log "Lock.qml already patched (dismissFadeToLock call present); skip"
fi

# --- 4. DMSShell.qml: add onDismissFadeToLock handler ---------------------
# perl -i -0pe for multi-line non-greedy match across the existing
# onCancelFadeToLock function body, inserting the sibling onDismissFadeToLock
# handler right after it inside the same Connections block.
if ! grep -q 'function onDismissFadeToLock' "$SHELL_FILE"; then
    log "Patching DMSShell.qml: add function onDismissFadeToLock handler"
    [ -f "$SHELL_FILE.backup" ] || sudo cp "$SHELL_FILE" "$SHELL_FILE.backup"

    sudo perl -i -0pe 's|(function onCancelFadeToLock\(\) \{.*?\n                \})|$1\n\n                function onDismissFadeToLock() {\n                    if (fadeWindowLoader.item) {\n                        fadeWindowLoader.item.dismiss();\n                    }\n                }|s' "$SHELL_FILE"

    if grep -q 'function onDismissFadeToLock' "$SHELL_FILE"; then
        log "  ok"
        CHANGES_MADE=true
    else
        log "  FAILED - restoring backup"
        sudo cp "$SHELL_FILE.backup" "$SHELL_FILE"
        exit 2
    fi
else
    log "DMSShell.qml already patched (onDismissFadeToLock present); skip"
fi

if $CHANGES_MADE; then
    log "Patch applied. Restart DMS to pick up the changes:"
    log "  systemctl --user restart dms.service"
else
    log "Nothing to do; all four files already patched."
fi
