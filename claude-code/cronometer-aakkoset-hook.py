#!/usr/bin/env python3
# PreToolUse: blocks Cronometer custom food and recipe writes that spell Finnish words without ä/ö.
import json
import os
import re
import sys

WORDS_FILE = os.path.join(os.path.dirname(os.path.realpath(__file__)), "cronometer-aakkoset-words.json")
URL_RE = re.compile(r"https?://\S+|\b[\w.-]+\.(?:fi|com|net|org|info|se|uk|de)\b\S*", re.I)
WORD_RE = re.compile(r"(?<![:\w])[A-Za-z]+(?![\w])")


def strings(value):
  if isinstance(value, str):
    yield value
  elif isinstance(value, dict):
    for v in value.values():
      yield from strings(v)
  elif isinstance(value, list):
    for v in value:
      yield from strings(v)


def main():
  payload = json.load(sys.stdin)
  with open(WORDS_FILE, encoding="utf-8") as f:
    words = json.load(f)

  hits = {}
  for text in strings(payload.get("tool_input", {})):
    for word in WORD_RE.findall(URL_RE.sub(" ", text)):
      fixed = words.get(word.lower())
      if fixed:
        hits[word] = fixed

  if not hits:
    return

  pairs = ", ".join(f"{w} -> {f}" for w, f in sorted(hits.items()))
  print(json.dumps({
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": f"Ääkköset puuttuvat: {pairs}. Korjaa teksti ja yritä uudelleen.",
    }
  }, ensure_ascii=False))


if __name__ == "__main__":
  main()
