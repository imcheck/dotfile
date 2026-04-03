#!/bin/bash
# Auto-approve read-only Bash commands for Claude Code.
# Unsafe or unrecognized commands fall through to normal permission handling.

set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# ── Always-safe commands (no subcommand check needed) ───────────────
SAFE_CMDS=(
  # File browsing
  find ls cat head tail wc tree file stat du df
  realpath readlink basename dirname pwd

  # Text processing
  grep egrep fgrep rg awk sed sort uniq cut tr
  jq yq column diff comm paste tee

  # Utilities
  echo printf date env which type command test true false
  base64 md5 shasum sha256sum
)
SAFE_LOOKUP=" ${SAFE_CMDS[*]} "

# ── Subcommand-gated commands ───────────────────────────────────────
# Only listed subcommands are auto-approved.

# git: read-only operations only
GIT_SAFE=" status log diff show branch tag rev-parse describe shortlog blame ls-files ls-tree ls-remote reflog cherry merge-base name-rev rev-list cat-file check-ignore check-attr for-each-ref symbolic-ref version help grep "

# kubectl: read-only operations only
KUBECTL_SAFE=" get describe logs top explain api-resources api-versions cluster-info version diff events wait completion "

# docker: read-only operations only
DOCKER_SAFE=" ps images logs inspect stats top port version info history search "

# ── Extract first positional arg (skip flags) ───────────────────────
first_positional() {
  for word in $1; do
    if [[ "$word" != -* ]]; then
      echo "$word"
      return
    fi
  done
}

# ── AWS: safe action-prefix check ───────────────────────────────────
check_aws() {
  local args="$1"
  local count=0 action=""
  for word in $args; do
    [[ "$word" == -* ]] && continue
    count=$((count + 1))
    if [[ $count -eq 2 ]]; then
      action="$word"
      break
    fi
  done
  [[ -z "$action" ]] && return 1
  case "$action" in
    describe-*|list-*|get-*|head-*|wait-*) return 0 ;;
    ls|presign|get-caller-identity) return 0 ;;
  esac
  return 1
}

# ── GH: two-level subcommand check ──────────────────────────────────
check_gh() {
  local args="$1"
  local count=0 subcmd="" sub2=""
  for word in $args; do
    [[ "$word" == -* ]] && continue
    count=$((count + 1))
    case $count in
      1) subcmd="$word" ;;
      2) sub2="$word"; break ;;
    esac
  done
  [[ -z "$subcmd" ]] && return 1
  case "$subcmd" in
    status) return 0 ;;
  esac
  [[ -z "$sub2" ]] && return 1
  case "$subcmd" in
    pr)       [[ " list view diff checks status " == *" $sub2 "* ]] && return 0 ;;
    issue)    [[ " list view status " == *" $sub2 "* ]] && return 0 ;;
    repo)     [[ " view " == *" $sub2 "* ]] && return 0 ;;
    run)      [[ " list view watch " == *" $sub2 "* ]] && return 0 ;;
    workflow) [[ " list view " == *" $sub2 "* ]] && return 0 ;;
    release)  [[ " list view " == *" $sub2 "* ]] && return 0 ;;
    auth)     [[ " status " == *" $sub2 "* ]] && return 0 ;;
  esac
  return 1
}

# ── Check if a command segment is safe ──────────────────────────────
is_safe() {
  local cmd_name="$1"
  local full_segment="$2"

  if [[ "$SAFE_LOOKUP" == *" $cmd_name "* ]]; then
    return 0
  fi

  local args="${full_segment#* }"
  [[ "$args" == "$full_segment" ]] && args=""

  local subcmd
  case "$cmd_name" in
    git)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$GIT_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    kubectl)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$KUBECTL_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    docker)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$DOCKER_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    aws)
      check_aws "$args" && return 0
      ;;
    gh)
      check_gh "$args" && return 0
      ;;
  esac

  return 1
}

# ── Main: parse and check all command segments ──────────────────────
cleaned=$(echo "$COMMAND" | sed -E 's/[0-9]*>[&]?[^ ]*//g; s/2>&1//g; s/<[^ ]*//g')

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

while IFS= read -r -d $'\003' segment || [[ -n "$segment" ]]; do
  trimmed=$(echo "$segment" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
  [[ -z "$trimmed" ]] && continue

  while [[ "$trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*=([^\ ]*) ]]; do
    trimmed=$(echo "$trimmed" | sed 's/^[A-Za-z_][A-Za-z0-9_]*=[^ ]* *//')
  done

  [[ -z "$trimmed" ]] && continue

  first_word=$(echo "$trimmed" | awk '{print $1}')
  [[ -z "$first_word" ]] && continue

  if [[ "$first_word" == */.claude/skills/* || "$first_word" == */.agents/skills/* ]]; then
    continue
  fi

  cmd_name=$(basename "$first_word")
  if ! is_safe "$cmd_name" "$trimmed"; then
    exit 0
  fi
done <<< "$segments"

echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"Command matches the read-only allowlist"}}'
