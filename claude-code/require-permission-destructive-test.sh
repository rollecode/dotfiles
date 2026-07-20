#!/usr/bin/env bash
# Feed each case in require-permission-destructive.cases.txt to the hook and check
# the decision matches. Columns: expected<TAB>command, expected is deny/ask/pass.
set -uo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
hook="$dir/require-permission-destructive.sh"
cases="$dir/require-permission-destructive.cases.txt"
fail=0
n=0

while IFS=$'\t' read -r want cmd; do
  [ -z "${want:-}" ] && continue
  n=$((n + 1))
  out=$(jq -nc --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$hook")
  if [ -z "$out" ]; then
    got=pass
  else
    got=$(jq -r '.hookSpecificOutput.permissionDecision' <<<"$out")
  fi
  if [ "$got" != "$want" ]; then
    printf 'FAIL want=%-5s got=%-5s %s\n' "$want" "$got" "$cmd"
    fail=$((fail + 1))
  fi
done < "$cases"

echo "cases: $n  failures: $fail"
[ "$fail" -eq 0 ]
