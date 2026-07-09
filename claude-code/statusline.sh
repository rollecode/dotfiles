#!/bin/bash
# Claude Code status line with Code::Stats XP and token usage
# Shows: Model · branch · 15k in 5k out · +156 -23 · XP: 123 (Shell)

input=$(cat)

# Extract session data
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')

# Detect the z.ai GLM and DeepSeek backends (direct native endpoints) from the raw model
# id. Bare "glm-*"/"deepseek-*" are direct; prefixed "z-ai/glm-*"/"deepseek/deepseek-*" via
# OpenRouter are billed by OpenRouter so their quota APIs do not apply, hence excluded.
IS_GLM=0
IS_DEEPSEEK=0
case "$MODEL" in
  glm-*)      IS_GLM=1 ;;
  deepseek-*) IS_DEEPSEEK=1 ;;
esac

# Prettify custom (non-Anthropic) model ids like "glm-5.2[1m]" or "z-ai/glm-5.2[1m]"
# into "GLM 5.2 (1M context)" to match Claude's own label style. Anthropic display
# names already contain spaces, so they are detected and left untouched.
CTX1M=""
case "$MODEL" in
  *"[1m]") CTX1M=" (1M context)"; MODEL="${MODEL%\[1m\]}" ;;
esac
MODEL="${MODEL##*/}"                 # drop provider prefix (z-ai/, deepseek/, ...)
if [[ "$MODEL" != *" "* ]]; then     # only reformat raw ids, never pretty Anthropic names
  case "$MODEL" in
    glm-*)      MODEL="GLM ${MODEL#glm-}" ;;
    deepseek-*) MODEL="DeepSeek ${MODEL#deepseek-}" ;;
    kimi-*)     MODEL="Kimi ${MODEL#kimi-}" ;;
    grok-*)     MODEL="Grok ${MODEL#grok-}" ;;
    qwen*)      MODEL="Qwen ${MODEL#qwen}" ;;
  esac
  MODEL="${MODEL//-/ }"              # remaining dashes to spaces
  MODEL="${MODEL/ air/ Air}"
  MODEL="${MODEL/ turbo/ Turbo}"
  MODEL="${MODEL/ pro/ Pro}"
  MODEL="${MODEL/ flash/ Flash}"
  MODEL="${MODEL/ non reasoning/ Non-Reasoning}"
  MODEL="${MODEL/ multi agent/ Multi-Agent}"
fi
MODEL="${MODEL}${CTX1M}"
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REM=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%.0f", $1}')

# Ensure numeric values have defaults
LINES_ADD=${LINES_ADD:-0}
LINES_REM=${LINES_REM:-0}
DURATION_MS=${DURATION_MS:-0}

# Format duration from ms to human readable
DURATION_S=$(( DURATION_MS / 1000 ))
DURATION_M=$(( DURATION_S / 60 ))
DURATION_H=$(( DURATION_M / 60 ))
if [ "$DURATION_H" -gt 0 ]; then
    DURATION_FMT="${DURATION_H}h $((DURATION_M % 60))m"
elif [ "$DURATION_M" -gt 0 ]; then
    DURATION_FMT="${DURATION_M}m"
else
    DURATION_FMT="${DURATION_S}s"
fi

# Colors (Catppuccin Mocha palette)
CYAN='\033[38;2;137;180;250m'
GREEN='\033[38;2;166;227;161m'
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
MAUVE='\033[38;2;203;166;247m'
DIM='\033[2m'
RESET='\033[0m'

# Read Code::Stats XP for today from counter file
XP_FILE="/tmp/codestats-xp-today"
TODAY=$(date '+%Y-%m-%d')
SESSION_XP=0
LAST_LANG=""

if [ -f "$XP_FILE" ]; then
    STORED_DATE=$(sed -n '1p' "$XP_FILE")
    if [ "$STORED_DATE" = "$TODAY" ]; then
        SESSION_XP=$(sed -n '2p' "$XP_FILE")
        LAST_LANG=$(sed -n '3p' "$XP_FILE")
    fi
fi

# Build output line
LINE="${CYAN}${MODEL}${RESET}"

# Duration and context %
LINE="${LINE} ${DIM}\xC2\xB7${RESET} \033[38;2;187;194;206m${DURATION_FMT}${RESET} ${DIM}\xC2\xB7${RESET} \033[38;2;171;179;241m${CTX_PCT}%${RESET}"

# Lines changed
if [ "$LINES_ADD" -gt 0 ] || [ "$LINES_REM" -gt 0 ]; then
    LINE="${LINE} ${DIM}\xC2\xB7${RESET} ${GREEN}+${LINES_ADD}${RESET} ${RED}-${LINES_REM}${RESET}"
fi

# XP with last gain
LAST_XP=""
[ -f /tmp/codestats-last-xp ] && LAST_XP=$(cat /tmp/codestats-last-xp 2>/dev/null)

if [ "$SESSION_XP" -gt 0 ]; then
    XP_PART="${YELLOW}XP: ${SESSION_XP}${RESET}"
    [ -n "$LAST_XP" ] && [ "$LAST_XP" -gt 0 ] 2>/dev/null && XP_PART="${XP_PART} ${YELLOW}+${LAST_XP}${RESET}"
    [[ "$LAST_LANG" == */* ]] && LAST_LANG=""
    [ -n "$LAST_LANG" ] && XP_PART="${XP_PART} ${DIM}(${LAST_LANG})${RESET}"
    LINE="${LINE} ${DIM}\xC2\xB7${RESET} ${XP_PART}"
fi

printf '%b\n' "$LINE"

# Second row: usage progress bars. On the z.ai GLM backend this shows the coding-plan
# quota (5-hour token cycle + weekly); otherwise Claude.ai's own 5-hour + 7-day limits.
PURPLE='\033[38;2;160;32;240m'
make_bar() {
    local pct=${1%.*}
    local label=$2
    local width=10
    local filled=$(( pct * width / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="━"; done
    for ((i=0; i<empty; i++)); do bar+="─"; done
    printf "${PURPLE}%s${RESET} ${PURPLE}%d%%${RESET} ${DIM}(%s)${RESET}" "$bar" "$pct" "$label"
}

GLM_KEY_FILE="$HOME/.config/zai/coding-key"
if [ "$IS_GLM" = 1 ] && [ -s "$GLM_KEY_FILE" ]; then
    # z.ai coding-plan quota: 5-hour token cycle (unit 3) + weekly quota (unit 6).
    # Cached with a background refresh so the statusline never blocks on the network.
    CACHE="/tmp/zai-quota.json"
    LOCK="/tmp/zai-quota.lock"
    TTL=60
    now=$(date +%s)
    lock_age=$TTL
    [ -f "$LOCK" ] && lock_age=$(( now - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -ge "$TTL" ]; then
        touch "$LOCK"
        ( curl -s --max-time 8 'https://api.z.ai/api/monitor/usage/quota/limit' \
            -H "Authorization: $(cat "$GLM_KEY_FILE")" \
            -H "Accept-Language: en-US,en" -H "Content-Type: application/json" \
            -o "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE" ) >/dev/null 2>&1 &
        disown 2>/dev/null
    fi
    if [ -s "$CACHE" ]; then
        G5=$(jq -r '[.data.limits[]|select(.type=="TOKENS_LIMIT" and .unit==3)][0].percentage // empty' "$CACHE" 2>/dev/null)
        GW=$(jq -r '[.data.limits[]|select(.type=="TOKENS_LIMIT" and .unit==6)][0].percentage // empty' "$CACHE" 2>/dev/null)
        GLVL=$(jq -r '.data.level // empty' "$CACHE" 2>/dev/null)
        if [ -n "$G5" ] || [ -n "$GW" ]; then
            LINE2=""
            [ -n "$G5" ] && LINE2="$(make_bar "$G5" "5h")"
            if [ -n "$GW" ]; then
                [ -n "$LINE2" ] && LINE2="${LINE2} ${DIM}\xC2\xB7${RESET} "
                LINE2="${LINE2}$(make_bar "$GW" "7d")"
            fi
            [ -n "$GLVL" ] && LINE2="${LINE2} ${DIM}\xC2\xB7 GLM ${GLVL}${RESET}"
            printf '%b\n' "$LINE2"
        fi
    fi
elif [ "$IS_DEEPSEEK" = 1 ] && [ -s "$HOME/.config/crush/deepseek-key" ]; then
    # DeepSeek account balance in dollars, straight from GET /user/balance (no separate
    # management key needed, unlike x.ai). Cached with a background refresh so the
    # status line never blocks on the network.
    DS_KEY_FILE="$HOME/.config/crush/deepseek-key"
    CACHE="/tmp/deepseek-balance.json"
    LOCK="/tmp/deepseek-balance.lock"
    TTL=60
    now=$(date +%s)
    lock_age=$TTL
    [ -f "$LOCK" ] && lock_age=$(( now - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -ge "$TTL" ]; then
        touch "$LOCK"
        ( curl -s --max-time 8 'https://api.deepseek.com/user/balance' \
            -H "Authorization: Bearer $(cat "$DS_KEY_FILE")" \
            -o "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE" ) >/dev/null 2>&1 &
        disown 2>/dev/null
    fi
    if [ -s "$CACHE" ]; then
        DOLLARS=$(jq -r '.balance_infos[0].total_balance // empty' "$CACHE" 2>/dev/null)
        [ -n "$DOLLARS" ] && printf "${PURPLE}\$%s${RESET} ${DIM}balance${RESET}\n" "$DOLLARS"
    fi
else
    FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
    WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
    if [ -n "$FIVE_H" ] || [ -n "$WEEK" ]; then
        LINE2=""
        if [ -n "$FIVE_H" ]; then
            LINE2="$(make_bar "$FIVE_H" "5h")"
        fi
        if [ -n "$WEEK" ]; then
            [ -n "$LINE2" ] && LINE2="${LINE2} ${DIM}\xC2\xB7${RESET} "
            LINE2="${LINE2}$(make_bar "$WEEK" "7d")"
        fi
        printf '%b\n' "$LINE2"
    fi
fi
