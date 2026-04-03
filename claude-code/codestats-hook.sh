#!/bin/bash

# Code::Stats integration for Claude Code
# Sends XP to code::stats for every file written/edited by Claude

# Get the directory where this script lives (follow symlinks)
# More robust path resolution that works on macOS
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    # If SOURCE is relative, resolve it relative to the symlink directory
    [[ $SOURCE != /* ]] && SOURCE="$SCRIPT_DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

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
        exit 0
        ;;
esac

# Skip if no content
if [ -z "$CONTENT" ] || [ "$CONTENT" == "null" ]; then
    exit 0
fi

# Calculate XP (1 XP per line, not per character, since Claude writes the code not the user)
XP=$(echo -n "$CONTENT" | wc -l | tr -d ' ')
# Add 1 if content doesn't end with newline (for single line edits)
if [ -n "$CONTENT" ] && [ "$(echo -n "$CONTENT" | tail -c 1)" != "" ]; then
    XP=$((XP + 1))
fi

# Skip if no XP to award
if [ "$XP" -eq 0 ]; then
    exit 0
fi

# Determine language from file extension
get_language() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local ext="${filename##*.}"

    # Special cases for filenames without extensions or special files
    if [ "$filename" = "$ext" ]; then
        case "$filename" in
            Dockerfile*) echo "Docker"; return ;;
            Makefile*) echo "Makefile"; return ;;
            LICENSE*) echo "Plain text"; return ;;
            .bashrc|.bash_profile|.bash_aliases|.inputrc) echo "Bash"; return ;;
            .zshrc|.zprofile) echo "Zsh"; return ;;
            .vimrc) echo "Vim script"; return ;;
            .gitignore|.gitattributes) echo "Git config"; return ;;
            .prettierignore|.eslintignore|.stylelintignore|.phpcsignore|.distignore) echo "Plain text"; return ;;
            .prettierrc|.eslintrc|.stylelintrc|.babelrc|.parcelrc|.sassrc|.luacheckrc|.screenrc|.nvmrc) echo "JSON"; return ;;
            .editorconfig|.env*) echo "Plain text"; return ;;
            *) echo "Plain text"; return ;;
        esac
    fi

    # Common extensions that need special handling
    case "$ext" in
        js|jsx|mjs|cjs) echo "JavaScript" ;;
        ts|tsx) echo "TypeScript" ;;
        py) echo "Python" ;;
        rb) echo "Ruby" ;;
        sh|bash) echo "Shell" ;;
        md|markdown) echo "Markdown" ;;
        yml|yaml) echo "YAML" ;;
        json|jsonc) echo "JSON" ;;
        lua) echo "Lua" ;;
        php) echo "PHP" ;;
        html|htm) echo "HTML" ;;
        css) echo "CSS" ;;
        scss|sass) echo "SCSS" ;;
        xml) echo "XML" ;;
        sql) echo "SQL" ;;
        rs) echo "Rust" ;;
        go) echo "Go" ;;
        java) echo "Java" ;;
        c|h) echo "C" ;;
        cpp|cc|cxx|hpp) echo "C++" ;;
        swift) echo "Swift" ;;
        toml) echo "TOML" ;;
        ini|cfg|conf) echo "Configuration" ;;
        csv) echo "CSV" ;;
        txt|text|log) echo "Plain text" ;;
        vim) echo "Vim script" ;;
        fish) echo "Shell" ;;
        plist|entitlements) echo "XML" ;;
        desktop) echo "Configuration" ;;
        timer|watch|service) echo "Systemd" ;;
        *) echo "Plain text" ;;
    esac
}

LANGUAGE=$(get_language "$FILE_PATH")

# Safeguard: never send a path as a language name
if [[ "$LANGUAGE" == */* ]] || [[ ${#LANGUAGE} -gt 30 ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') BLOCKED path-as-lang: FILE_PATH=$FILE_PATH LANGUAGE=$LANGUAGE" >> /tmp/codestats-debug.log
    LANGUAGE="Plain text"
fi

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

# Show notification based on response
if [ "$HTTP_CODE" = "201" ]; then
    MESSAGE="+XP ${XP} (${LANGUAGE})"

    # Update daily XP counter for statusline (resets each day)
    TODAY=$(date '+%Y-%m-%d')
    XP_FILE="/tmp/codestats-xp-today"
    STORED_DATE=""
    STORED_XP=0
    if [ -f "$XP_FILE" ]; then
        STORED_DATE=$(sed -n '1p' "$XP_FILE")
        STORED_XP=$(sed -n '2p' "$XP_FILE")
    fi
    if [ "$STORED_DATE" != "$TODAY" ]; then
        STORED_XP=0
    fi
    printf '%s\n%d\n%s\n' "$TODAY" "$((STORED_XP + XP))" "$LANGUAGE" > "$XP_FILE"

    # Write last gain for status line display
    echo "$XP" > /tmp/codestats-last-xp

    # Output as systemMessage for non-blocking inline display in Claude Code
    echo "{\"systemMessage\": \"${MESSAGE}\"}"
    exit 0
else
    exit 0
fi
