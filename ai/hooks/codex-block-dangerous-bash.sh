#!/bin/bash
# Block a small set of clearly destructive Bash commands for Codex.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
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
