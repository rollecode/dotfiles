#!/usr/bin/env bash
# Marks the zellij tab with an icon when Claude needs input (waiting) or has
# finished (completed). Silent no-op outside zellij.

set -uo pipefail

event="${1:-waiting}"

[ -n "${ZELLIJ:-}" ] || exit 0
[ -n "${ZELLIJ_PANE_ID:-}" ] || exit 0
command -v zellij >/dev/null 2>&1 || exit 0

zellij pipe --name "zellij-attention::${event}::${ZELLIJ_PANE_ID}" >/dev/null 2>&1 || true
exit 0
