#!/usr/bin/env python3
# PreToolUse: blocks writes to Dude-facing services (Linear, Slack, Outline, Twenty,
# Timely, Calendar, Better Stack) that name a personal server or project.
# The list lives in the Brain dump, not here, because this repo is public.
import json
import os
import re
import sys

TERMS_FILE = os.environ.get(
  "PERSONAL_TERMS_FILE", os.path.expanduser("~/Documents/Brain dump/personal-terms.txt")
)
WORK_SERVICE_WRITE = re.compile(
  r"^mcp__(linear|claude_ai_Slack|claude_ai_Outline|twenty|timely|claude_ai_Google_Calendar|betterstack)__"
  r"(.*[_-])?(save|create|update|upsert|merge|add|send|draft|schedule|share|post|edit)([_-]|$)"
)
WORK_API_IN_BASH = re.compile(r"api\.linear\.app|slack\.com/api|docs\.dude\.fi|crm\.dude\.fi")


def personal_term(text):
  try:
    with open(TERMS_FILE, encoding="utf-8") as f:
      terms = [l.strip() for l in f if l.strip() and not l.lstrip().startswith("#")]
  except OSError:
    return None

  for term in terms:
    # A "re:" line is a case-sensitive regex, for words that are also ordinary ones (git stash).
    try:
      if term.startswith("re:"):
        found = re.search(term[3:], text)
      else:
        found = re.search(rf"(?<!\w){re.escape(term)}(?!\w)", text, re.I)
    except re.error:
      continue
    if found:
      return term
  return None


def main():
  payload = json.load(sys.stdin)
  tool = payload.get("tool_name", "")
  text = re.sub(r"\\[nrt]", " ", json.dumps(payload.get("tool_input", {}), ensure_ascii=False))
  if not (WORK_SERVICE_WRITE.search(tool) or (tool == "Bash" and WORK_API_IN_BASH.search(text))):
    return

  term = personal_term(text)
  if not term:
    return

  print(json.dumps({
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": f'Blocked: this goes to a Dude service and names "{term}", one of '
        "Rolle's personal servers or projects. Rewrite it without any personal server or project, or leave it out.",
    }
  }))


if __name__ == "__main__":
  try:
    main()
  except Exception:
    pass
