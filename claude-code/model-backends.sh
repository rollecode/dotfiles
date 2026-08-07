#!/bin/bash
# obsidian://open?vault=Brain%20dump&file=Claude%20Code%20alternative%20backends
# Claude Code against non-Anthropic backends via NATIVE Anthropic endpoints (no proxy).
# /compact, --resume, thinking blocks and tier-switching all work because these speak
# Claude Code's own protocol. Flags pass through to claude via "$@".
#
# No secrets live here - each function reads its key from a local file under
# ~/.config/. Source this file from .bashrc/.bash_profile on every machine and
# drop the matching key file in place; nothing below is machine-specific.

# GLM via z.ai's native Anthropic endpoint (drop-in). Tier vars keep auto/model-switch on.
# Key: ~/.config/zai/coding-key
claudeglm() {
  ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$(cat ~/.config/zai/coding-key 2>/dev/null)" \
  API_TIMEOUT_MS=3000000 \
  ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.2" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="glm-5.2" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air" \
  claude "$@"
}

# Any model via OpenRouter's native Anthropic endpoint. Exports (not inline vars)
# so subagents also reach OR, per official docs. Three tiers, three providers:
#   Opus   -> z-ai/glm-5.2          (cheapest agentic, $0.93/$3.00/M)
#   Sonnet -> minimax/minimax-m3     (balanced, 1M ctx, $0.30/$1.20/M)
#   Haiku  -> z-ai/glm-5.2          (same, no cheaper good option on OR yet)
# Kimi 400s through Claude Code (upstream OR capacity), not used.
# Key: $OPENROUTER_API_KEY (already exported elsewhere)
claudeor() {
  export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
  export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
  export ANTHROPIC_API_KEY=""
  export ANTHROPIC_DEFAULT_OPUS_MODEL="${OR_MODEL:-z-ai/glm-5.2}"
  export ANTHROPIC_DEFAULT_SONNET_MODEL="${OR_MODEL:-minimax/minimax-m3}"
  export ANTHROPIC_DEFAULT_HAIKU_MODEL="${OR_SMALL:-${OR_MODEL:-z-ai/glm-5.2}}"
  claude "$@"
}

# DeepSeek via its native Anthropic endpoint (https://api.deepseek.com/anthropic).
# Proxy-free, confirmed working end-to-end 9.7.2026. Cheapest option: V4 Pro ~$0.435
# in/$0.87 out, V4 Flash ~$0.14 in/$0.28 out per M tokens (cache-hit input down to
# $0.0028/M). Default driver for low-stakes/high-volume work while Claude is on extra
# usage billing and GLM lite's daily quota is burned (both true as of 9.7.2026).
# Key: ~/.config/crush/deepseek-key
claudeds() {
  ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$(cat ~/.config/crush/deepseek-key 2>/dev/null)" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="${DS_MODEL:-deepseek-v4-pro}" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="${DS_MODEL:-deepseek-v4-pro}" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="${DS_SMALL:-deepseek-v4-flash}" \
  claude "$@"
}

# Qwen via DashScope's native Anthropic endpoint (pay-as-you-go, international).
# Confirmed working end-to-end 7.8.2026 against https://dashscope-intl.aliyuncs.com/apps/anthropic.
# Qwen3.8-Max: $2/M in, $6/M out, flat across the full 1M context. Flash tier is the
# cheap driver for low-stakes/high-volume work, same role DeepSeek plays above.
# Key: ~/.config/qwen/dashscope-key
claudeqwen() {
  ANTHROPIC_BASE_URL="https://dashscope-intl.aliyuncs.com/apps/anthropic" \
  ANTHROPIC_AUTH_TOKEN="$(cat ~/.config/qwen/dashscope-key 2>/dev/null)" \
  ANTHROPIC_DEFAULT_OPUS_MODEL="${QWEN_MODEL:-qwen3.8-max}" \
  ANTHROPIC_DEFAULT_SONNET_MODEL="${QWEN_MODEL:-qwen3.8-max}" \
  ANTHROPIC_DEFAULT_HAIKU_MODEL="${QWEN_SMALL:-qwen3.6-flash}" \
  claude "$@"
}
