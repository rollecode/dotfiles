#!/bin/bash

# Code::Stats integration for Claude Code
# Sends XP to code::stats for every file written/edited by Claude

# Get the directory where this script lives (follow symlinks)
if [ -L "${BASH_SOURCE[0]}" ]; then
    SCRIPT_PATH="$(readlink "${BASH_SOURCE[0]}")"
else
    SCRIPT_PATH="${BASH_SOURCE[0]}"
fi
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

# Source the secrets file
if [ -f "$SCRIPT_DIR/secrets.sh" ]; then
    source "$SCRIPT_DIR/secrets.sh"
else
    echo "Error: secrets.sh not found. Copy secrets.sh.example to secrets.sh and add your API key." >&2
    exit 1
fi

# Check if API key is set
if [ -z "$CODESTATS_API_KEY" ] || [ "$CODESTATS_API_KEY" == "YOUR_API_KEY_HERE" ]; then
    echo "Error: CODESTATS_API_KEY not set in secrets.sh" >&2
    exit 1
fi

CODESTATS_API_URL="https://codestats.net/api/my/pulses"

# Read the hook input from stdin
INPUT=$(cat)

# Extract tool information
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file path (some tools don't modify files)
if [ -z "$FILE_PATH" ] || [ "$FILE_PATH" == "null" ]; then
    exit 0
fi

# Calculate XP based on tool type
case "$TOOL_NAME" in
    "Edit")
        # For Edit tool, count characters in new_string
        CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
        ;;
    "Write")
        # For Write tool, count characters in content
        CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
        ;;
    "NotebookEdit")
        # For NotebookEdit tool, count characters in new_source
        CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_source // empty')
        ;;
    *)
        # Unknown tool, skip
        exit 0
        ;;
esac

# Skip if no content
if [ -z "$CONTENT" ] || [ "$CONTENT" == "null" ]; then
    exit 0
fi

# Calculate XP (1 XP per character)
XP=$(echo -n "$CONTENT" | wc -c | tr -d ' ')

# Skip if no XP to award
if [ "$XP" -eq 0 ]; then
    exit 0
fi

# Determine language from file extension
get_language() {
    local filepath="$1"
    local ext="${filepath##*.}"
    local filename=$(basename "$filepath")

    # Special cases for filenames without extensions or special files
    if [ "$filename" = "$ext" ]; then
        case "$filename" in
            Dockerfile*) echo "Dockerfile"; return ;;
            Makefile*) echo "Makefile"; return ;;
            .bashrc|.bash_profile|.bash_aliases) echo "Bash"; return ;;
            .zshrc|.zprofile) echo "Zsh"; return ;;
            .vimrc) echo "Vim script"; return ;;
            *) echo "Plain text"; return ;;
        esac
    fi

    # Common extensions that need special handling
    case "$ext" in
        js|jsx|mjs|cjs) echo "JavaScript" ;;
        ts|tsx) echo "TypeScript" ;;
        py) echo "Python" ;;
        rb) echo "Ruby" ;;
        sh) echo "Shell" ;;
        md|markdown) echo "Markdown" ;;
        yml) echo "YAML" ;;
        # For everything else, just capitalize the extension
        *) echo "$ext" | tr '[:lower:]' '[:upper:]' ;;
    esac
}

LANGUAGE=$(get_language "$FILE_PATH")

# Create timestamp in RFC 3339 format with local timezone
TIMESTAMP=$(date "+%Y-%m-%dT%H:%M:%S%z" | sed 's/\([0-9][0-9]\)$/:\1/')

# Create JSON payload
PAYLOAD=$(jq -n \
    --arg timestamp "$TIMESTAMP" \
    --arg language "$LANGUAGE" \
    --argjson xp "$XP" \
    '{
        coded_at: $timestamp,
        xps: [
            {
                language: $language,
                xp: $xp
            }
        ]
    }')

# Send to Code::Stats API and capture response
RESPONSE=$(curl -X POST "$CODESTATS_API_URL" \
    -H "Content-Type: application/json" \
    -H "X-API-Token: $CODESTATS_API_KEY" \
    -H "User-Agent: Claude-Code-CodeStats/1.0" \
    -d "$PAYLOAD" \
    --silent \
    --show-error \
    -w "\n%{http_code}" 2>&1)

# Extract HTTP status code (last line)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

# Catppuccin Mocha Yellow: #f9e2af (RGB 249, 226, 175)
YELLOW='\033[38;2;249;226;175m'
RED='\033[38;2;243;139;168m'
RESET='\033[0m'

# Log file location
LOG_FILE="$HOME/.claude/codestats-hook.log"
DEBUG_LOG_FILE="$HOME/.claude/codestats-hook-debug.log"

# Show notification based on response
if [ "$HTTP_CODE" = "201" ]; then
    MESSAGE="+XP ${XP} (${LANGUAGE})"
    echo -e "${YELLOW}${MESSAGE}${RESET}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${MESSAGE}" >> "$LOG_FILE"
else
    MESSAGE="code::stats error (HTTP ${HTTP_CODE})"
    echo -e "${RED}${MESSAGE}${RESET}" >&2
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ${MESSAGE}" >> "$LOG_FILE"
fi

exit 0
