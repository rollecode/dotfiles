#!/bin/bash
# Claude Code status line with Code::Stats XP and token usage
# Shows: Model · branch · 15k in 5k out · +156 -23 · XP: 123 (Shell)

input=$(cat)

# Extract session data
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
IN_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REM=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# Format token counts: round to nearest k/M, no decimals
fmt_tokens() {
    local n=$1
    if [ "$n" -ge 1000000 ]; then
        printf '%dM' $(( (n + 500000) / 1000000 ))
    elif [ "$n" -ge 1000 ]; then
        printf '%dk' $(( (n + 500) / 1000 ))
    else
        printf '%d' "$n"
    fi
}

IN_FMT=$(fmt_tokens "$IN_TOKENS")
OUT_FMT=$(fmt_tokens "$OUT_TOKENS")

# Colors (Catppuccin Mocha palette)
CYAN='\033[38;2;137;180;250m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
MAUVE='\033[38;2;203;166;247m'
DIM='\033[2m'
RESET='\033[0m'

# Read Code::Stats XP for today
XP_LOG="$HOME/.claude/codestats-hook.log"
TODAY=$(date '+%Y-%m-%d')
SESSION_XP=0
LAST_LANG=""

if [ -f "$XP_LOG" ]; then
    while IFS= read -r line; do
        xp_val=$(echo "$line" | grep -oP '\+XP \K[0-9]+')
        [ -n "$xp_val" ] && SESSION_XP=$((SESSION_XP + xp_val))
        lang=$(echo "$line" | grep -oP '\(\K[^)]+')
        [ -n "$lang" ] && LAST_LANG="$lang"
    done < <(grep "^${TODAY}" "$XP_LOG")
fi

# Build output line
LINE="${CYAN}${MODEL}${RESET}"

# Tokens
LINE="${LINE} ${DIM}\xC2\xB7 ${IN_FMT} in \xC2\xB7 ${OUT_FMT} out${RESET}"

# Lines changed
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_REM" -gt 0 ]; then
    LINE="${LINE} ${DIM}\xC2\xB7${RESET} ${GREEN}+${LINES_ADD}${RESET} ${RED}-${LINES_REM}${RESET}"
fi

# XP with last gain
LAST_XP=""
[ -f /tmp/codestats-last-xp ] && LAST_XP=$(cat /tmp/codestats-last-xp 2>/dev/null)

if [ "$SESSION_XP" -gt 0 ]; then
    XP_PART="${YELLOW}XP: ${SESSION_XP}${RESET}"
    [ -n "$LAST_XP" ] && [ "$LAST_XP" -gt 0 ] 2>/dev/null && XP_PART="${XP_PART} ${GREEN}+${LAST_XP}${RESET}"
    [ -n "$LAST_LANG" ] && XP_PART="${XP_PART} ${DIM}(${LAST_LANG})${RESET}"
    LINE="${LINE} ${DIM}\xC2\xB7${RESET} ${XP_PART}"
fi

printf '%b\n' "$LINE"
