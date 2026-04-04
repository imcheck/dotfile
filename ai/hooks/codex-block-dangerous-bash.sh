#!/bin/bash
# Block a small set of clearly destructive Bash commands for Codex.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

cleaned=$(echo "$COMMAND" | sed -E 's/[0-9]*>[&]?[^ ]*//g; s/2>&1//g; s/<[^ ]*//g')

# Short-circuit trusted installed skill entrypoints. Codex treats the absence
# of hook output as "allow", and only needs explicit JSON for blocking.
segments=$(printf '%s' "$cleaned" | awk 'BEGIN { RS = "\003" }
{
  in_sq = 0; in_dq = 0; seg = ""
  for (i = 1; i <= length($0); i++) {
    c = substr($0, i, 1)
    c2 = substr($0, i, 2)
    if (c == "\"" && !in_sq) { in_dq = !in_dq; seg = seg c; continue }
    if (c == "\047" && !in_dq) { in_sq = !in_sq; seg = seg c; continue }
    if (in_sq || in_dq) { seg = seg c; continue }
    if (c2 == "&&" || c2 == "||") { printf "%s\003", seg; seg = ""; i++; continue }
    if (c == "|" || c == ";") { printf "%s\003", seg; seg = ""; continue }
    seg = seg c
  }
  if (seg != "") printf "%s\003", seg
}')

all_skill_segments=true
has_segment=false
while IFS= read -r -d $'\003' segment || [[ -n "$segment" ]]; do
  trimmed=$(echo "$segment" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [[ -z "$trimmed" ]] && continue

  while [[ "$trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*=([^[:space:]]*) ]]; do
    trimmed=$(echo "$trimmed" | sed 's/^[A-Za-z_][A-Za-z0-9_]*=[^ ]* *//')
  done

  [[ -z "$trimmed" ]] && continue

  first_word=$(echo "$trimmed" | awk '{print $1}')
  [[ -z "$first_word" ]] && continue

  has_segment=true
  if [[ "$first_word" == */.agents/skills/* || "$first_word" == */.claude/skills/* ]]; then
    continue
  fi

  all_skill_segments=false
  break
done <<< "$segments"

if [[ "$has_segment" == true && "$all_skill_segments" == true ]]; then
  exit 0
fi

normalized=$(printf '%s' "$COMMAND" | tr '\n' ' ')
reason=""

if echo "$normalized" | rg -q '(^|[[:space:]])git reset --hard([[:space:]]|$)|(^|[[:space:]])git clean -f[dDxX]*([[:space:]]|$)'; then
  reason="Blocked a destructive git cleanup command."
elif echo "$normalized" | rg -q '(^|[[:space:]])(shutdown|reboot|poweroff|halt)([[:space:]]|$)'; then
  reason="Blocked a system shutdown or reboot command."
elif echo "$normalized" | rg -q '(^|[[:space:]])(mkfs(\.[^[:space:]]+)?|fdisk|diskutil eraseDisk)([[:space:]]|$)'; then
  reason="Blocked a disk formatting command."
elif echo "$normalized" | rg -q '(^|[[:space:]])dd[[:space:]].*of=/dev/'; then
  reason="Blocked a raw disk write command."
elif echo "$normalized" | rg -q '(^|[[:space:]])curl[[:space:]].*\|[[:space:]]*(sh|bash)([[:space:]]|$)|(^|[[:space:]])wget[[:space:]].*\|[[:space:]]*(sh|bash)([[:space:]]|$)'; then
  reason="Blocked piping a downloaded script directly into a shell."
elif echo "$normalized" | rg -q '(^|[[:space:]])rm[[:space:]].*-rf[[:space:]]+(/|~|\$HOME)([[:space:]]|$)'; then
  reason="Blocked a recursive delete targeting the root or home directory."
fi

if [[ -n "$reason" ]]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$reason\"}}"
fi
