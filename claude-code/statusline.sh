#!/bin/bash
# Claude Code status line with Code::Stats XP and token usage
# Shows: Account · Model · branch · 15k in 5k out · +156 -23 · XP: 123 (Shell)

input=$(cat)

# Which subscription this session is authenticated as. Rolle runs two
# accounts (Max and Team) under the same email, so the email tells him
# nothing - only the plan name distinguishes them, and the only way to read
# that otherwise is to grep ~/.claude.json by hand.
#
# Official plan names are "Max 20x" and "Team 6.25x". The multiplier lives in
# a DIFFERENT field depending on account type - confirmed by reading both live:
#   Max:  organizationRateLimitTier = "default_claude_max_20x"  -> parse the "20"
#   Team: organizationRateLimitTier = "default_raven" (an internal codename,
#         no multiplier in it at all); the multiplier is really encoded in
#         seatTier ("team_tier_1" confirmed = 6.25x), which needs a lookup
#         table rather than a parse since Anthropic's tier-name -> multiplier
#         mapping is not published anywhere. Add a row here if another team
#         tier shows up; an unmapped one falls back to the bare seatTier
#         string rather than a guessed number.
ACCOUNT_TAG=""
if [ -f "$HOME/.claude.json" ]; then
    ACCOUNT_TAG=$(jq -r '
        .oauthAccount // empty
        | (.organizationType // "") as $type
        | (.organizationRateLimitTier // "") as $rateTier
        | (.seatTier // "") as $seat
        | {"team_tier_1": "6.25x"} as $teamTierMultipliers
        | (if $type == "claude_max" then "Max"
           elif $type == "claude_team" then "Team"
           elif $type == "claude_pro" then "Pro"
           elif $type != "" then $type
           else "Account" end) as $planLabel
        | if $type == "claude_team" then
            if $teamTierMultipliers[$seat] then $planLabel + " " + $teamTierMultipliers[$seat]
            elif $seat != "" then $planLabel + " (" + $seat + ")"
            else $planLabel end
          else
            ([$rateTier | capture("_(?<mult>[0-9]+(?:[._][0-9]+)?)x$")?] | first.mult) as $mult
            | if $mult then $planLabel + " " + ($mult | gsub("_"; ".")) + "x" else $planLabel end
          end
    ' "$HOME/.claude.json" 2>/dev/null)
fi
# Record the plan's live 5h/7d utilisation to the pace ledger. Backgrounded so a
# slow disk can never stall the status line, and silent so it can never corrupt it.
( printf '%s' "$input" | "$HOME/.claude/usage-pace-record.sh" >/dev/null 2>&1 & ) 2>/dev/null
# Same deal for the ongoing monthly $ spend estimate on backends with no usable
# balance/spend API of their own (DeepSeek, Qwen).
( printf '%s' "$input" | "$HOME/.claude/model-spend-record.sh" >/dev/null 2>&1 & ) 2>/dev/null

# Extract session data
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')

# Detect the z.ai GLM and DeepSeek backends (direct native endpoints) from the raw model
# id. Bare "glm-*"/"deepseek-*" are direct; prefixed "z-ai/glm-*"/"deepseek/deepseek-*" via
# OpenRouter are billed by OpenRouter so their quota APIs do not apply, hence excluded.
IS_GLM=0
IS_DEEPSEEK=0
IS_QWEN=0
IS_OR=0
case "$MODEL" in
  glm-*)      IS_GLM=1 ;;
  deepseek-*) IS_DEEPSEEK=1 ;;
  qwen*)      IS_QWEN=1 ;;
  */*)        IS_OR=1 ;;     # provider/model prefix = OpenRouter
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
    minimax-*)  MODEL="MiniMax ${MODEL#minimax-}" ;;
  esac
  MODEL="${MODEL//-/ }"              # remaining dashes to spaces
  MODEL="${MODEL/ air/ Air}"
  MODEL="${MODEL/ turbo/ Turbo}"
  MODEL="${MODEL/ pro/ Pro}"
  MODEL="${MODEL/ flash/ Flash}"
  MODEL="${MODEL/ max/ Max}"
  MODEL="${MODEL/ lite/ Lite}"
  MODEL="${MODEL/ preview/ Preview}"
  MODEL="${MODEL/ non reasoning/ Non-Reasoning}"
  MODEL="${MODEL/ multi agent/ Multi-Agent}"
fi
MODEL="${MODEL}${CTX1M}"

# Reasoning effort: live session value, lowercase, absent when the model has no
# effort param. Colour ramps with cost: low/medium green, high yellow, xhigh red,
# max a bolder screaming red.
EFFORT=$(echo "$input" | jq -r '.effort.level // empty')

DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REM=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%.0f", $1}')

# Rate-limit usage, rendered as inline bars on the first row (Anthropic backends).
# Empty on backends that report quota elsewhere (GLM, DeepSeek, ...).
FIVE_H=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
WEEK=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
WEEK_RESET=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

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
GOLD='\033[38;2;212;175;55m'
PURPLE='\033[38;2;160;32;240m'
SCREAM='\033[1m\033[38;2;255;0;0m'   # bold pure red for max
DIM='\033[2m'
RESET='\033[0m'

# Map effort level to a colour once, here where the palette is defined.
EFFORT_COLOR=""
case "$EFFORT" in
    low|medium) EFFORT_COLOR="$GREEN" ;;
    high)       EFFORT_COLOR="$YELLOW" ;;
    xhigh)      EFFORT_COLOR="$RED" ;;
    max)        EFFORT_COLOR="$SCREAM" ;;
esac

# Narrow usage bar, shown inline on the first row.
make_bar() {
    local pct=${1%.*}
    local label=$2
    local width=6
    local filled=$(( pct * width / 100 ))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$(( width - filled ))
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="━"; done
    for ((i=0; i<empty; i++)); do bar+="─"; done
    printf "${PURPLE}%s${RESET} ${PURPLE}%d%%${RESET} ${DIM}%s${RESET}" "$bar" "$pct" "$label"
}

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
LINE=""
if [ -n "$ACCOUNT_TAG" ]; then
    LINE="${MAUVE}${ACCOUNT_TAG}${RESET} ${DIM}\xC2\xB7${RESET} "
fi
LINE="${LINE}${CYAN}${MODEL}${RESET}"

# Effort, between model and duration
if [ -n "$EFFORT" ]; then
    LINE="${LINE} ${DIM}\xC2\xB7${RESET} ${EFFORT_COLOR}${EFFORT}${RESET}"
fi

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

# Usage bars inline on the first row (Anthropic backends). Other backends report
# their quota/balance below, since it needs a network fetch first.
if [ -n "$FIVE_H" ] || [ -n "$WEEK" ]; then
    USAGE_BARS=""
    [ -n "$FIVE_H" ] && USAGE_BARS="$(make_bar "$FIVE_H" "5h")"
    if [ -n "$WEEK" ]; then
        [ -n "$USAGE_BARS" ] && USAGE_BARS="${USAGE_BARS}  "
        USAGE_BARS="${USAGE_BARS}$(make_bar "$WEEK" "7d")"
        # Hours until the 7-day window resets, rounded up so it never reads 0h early.
        if [ -n "$WEEK_RESET" ]; then
            RH=$(( (WEEK_RESET - $(date +%s) + 3599) / 3600 ))
            [ "$RH" -lt 0 ] && RH=0
            USAGE_BARS="${USAGE_BARS} ${DIM}reset in ${RH}h${RESET}"
        fi
    fi
    LINE="${LINE}  ${USAGE_BARS}"
fi

printf '%b\n' "$LINE"

# Reads the running monthly total model-spend-record.sh maintains for a provider
# (deepseek/qwen). Empty output if there is no current-month total yet.
month_spend() {
    local f="$HOME/.claude/spend/monthly-$1.json"
    [ -s "$f" ] || return 0
    local this_month; this_month=$(date '+%Y-%m')
    jq -r --arg m "$this_month" 'if .month == $m then (.total | tostring) else empty end' "$f" 2>/dev/null \
        | awk '{printf "%.2f", $1}'
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
        MTD=$(month_spend "deepseek")
        if [ -n "$DOLLARS" ]; then
            LINE2="${GOLD}\$${DOLLARS}${RESET} ${DIM}balance${RESET}"
            [ -n "$MTD" ] && LINE2="${LINE2} ${DIM}\xC2\xB7${RESET} ${GOLD}~\$${MTD}${RESET} ${DIM}this month${RESET}"
            printf '%b\n' "$LINE2"
        fi
    fi
elif [ "$IS_QWEN" = 1 ]; then
    # No usable balance/spend API on DashScope's pay-as-you-go tier with a plain
    # bearer key (PAYG billing lives behind Alibaba Cloud's signed BSS API), so
    # this is the locally estimated running total from model-spend-record.sh.
    MTD=$(month_spend "qwen")
    [ -n "$MTD" ] && printf '%b\n' "${GOLD}~\$${MTD}${RESET} ${DIM}this month${RESET}"
elif [ "$IS_OR" = 1 ] && [ -s "$HOME/.config/crush/openrouter-key" ]; then
    # OpenRouter monthly credit usage (GET /api/v1/auth/key). Cached + background-refreshed.
    OR_KEY_FILE="$HOME/.config/crush/openrouter-key"
    CACHE="/tmp/or-credits.json"
    LOCK="/tmp/or-credits.lock"
    TTL=60
    now=$(date +%s)
    lock_age=$TTL
    [ -f "$LOCK" ] && lock_age=$(( now - $(stat -c %Y "$LOCK" 2>/dev/null || echo 0) ))
    if [ "$lock_age" -ge "$TTL" ]; then
        touch "$LOCK"
        ( curl -s --max-time 8 "https://openrouter.ai/api/v1/auth/key" \
            -H "Authorization: Bearer $(cat "$OR_KEY_FILE")" \
            -o "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE" ) >/dev/null 2>&1 &
        disown 2>/dev/null
    fi
    if [ -s "$CACHE" ]; then
        USED=$(jq -r '.data.usage // empty' "$CACHE" 2>/dev/null)
        LIMIT=$(jq -r '.data.limit // empty' "$CACHE" 2>/dev/null)
        [ -n "$USED" ] && [ -n "$LIMIT" ] && awk -v u="$USED" -v l="$LIMIT" 'BEGIN{printf "'"${GOLD}"'$%.2f'"${RESET}"' '"${DIM}"'/ $%.0f this month'"${RESET}"'\n", u, l}'
    fi
fi
# Anthropic 5h/7d usage renders inline on the first row, so there is no default
# second row here.
