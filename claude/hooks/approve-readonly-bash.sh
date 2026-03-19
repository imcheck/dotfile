#!/bin/bash
# Auto-approve safe bash commands, including piped/chained commands.
# Commands with subcommands (git, kubectl, etc.) are checked at the subcommand level.
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
  jq yq column diff comm paste tee xargs

  # Utilities
  echo printf date env which type command test true false
  curl wget openssl base64 md5 shasum sha256sum
  npm npx node python python3 pip

  # Context switchers / navigation
  cd kubectx kubens saml2aws
)
SAFE_LOOKUP=" ${SAFE_CMDS[*]} "

# ── Subcommand-gated commands ───────────────────────────────────────
# Only listed subcommands are auto-approved.
# Unlisted subcommands (push, reset, apply, delete, ...) prompt the user.

# git: local/read-only ops (excludes push, reset, clean, checkout, merge, rebase, pull)
GIT_SAFE=" status log diff show branch tag remote rev-parse describe shortlog blame ls-files ls-tree ls-remote config reflog cherry merge-base name-rev rev-list cat-file check-ignore check-attr for-each-ref symbolic-ref fetch stash worktree version help add commit am format-patch range-diff bisect notes grep rerere pull "

# kubectl: read-only ops (excludes apply, create, delete, edit, patch, exec, scale, drain, cordon, taint, label, annotate, rollout)
KUBECTL_SAFE=" get describe logs top explain api-resources api-versions cluster-info config version auth diff events wait completion "

# helm: read-only ops (excludes install, upgrade, uninstall, rollback)
HELM_SAFE=" list ls status get show search history version env template lint verify diff repo dep dependency "

# terraform: read-only/planning ops (excludes apply, destroy, import, taint, untaint)
TERRAFORM_SAFE=" init plan show output providers version validate fmt graph console get "

# docker: read-only ops (excludes run, exec, rm, rmi, stop, kill, start, build, push, pull, create, system)
DOCKER_SAFE=" ps images logs inspect stats top port version info history search "

# istioctl: diagnostic ops (excludes install, uninstall, upgrade, kube-inject)
ISTIOCTL_SAFE=" analyze version proxy-config proxy-status dashboard verify-install bug-report experimental "

# tmux: read-only ops (excludes send-keys, send-prefix, kill-*, new-*, split-window, respawn-pane)
TMUX_SAFE=" list-sessions list-windows list-panes list-buffers list-commands list-keys display-message display-panes show-options show-environment show-buffer capture-pane info source-file has-session select-window select-pane last-window last-pane switch-client "

# ── Extract first positional arg (skip flags) ──────────────────────
first_positional() {
  for word in $1; do
    if [[ "$word" != -* ]]; then
      echo "$word"
      return
    fi
  done
}

# ── AWS: safe action-prefix check ──────────────────────────────────
# Pattern: aws <service> <action>
# Safe actions: describe-*, list-*, get-*, head-*, wait-*, plus specific safe commands
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
    ls|presign|get-caller-identity|update-kubeconfig) return 0 ;;
  esac
  return 1
}

# ── GH: two-level subcommand check ─────────────────────────────────
# Safe: read-only operations. Excludes create, merge, close, comment, delete, edit, api
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
  # Single-level safe commands
  case "$subcmd" in
    status) return 0 ;;
  esac
  [[ -z "$sub2" ]] && return 1
  # Two-level safe commands
  case "$subcmd" in
    pr)       [[ " list view diff checks status " == *" $sub2 "* ]] && return 0 ;;
    issue)    [[ " list view status " == *" $sub2 "* ]] && return 0 ;;
    repo)     [[ " list view clone " == *" $sub2 "* ]] && return 0 ;;
    run)      [[ " list view watch " == *" $sub2 "* ]] && return 0 ;;
    workflow) [[ " list view " == *" $sub2 "* ]] && return 0 ;;
    release)  [[ " list view " == *" $sub2 "* ]] && return 0 ;;
    auth)     [[ " status login " == *" $sub2 "* ]] && return 0 ;;
  esac
  return 1
}

# ── Check if a command segment is safe ──────────────────────────────
is_safe() {
  local cmd_name="$1"
  local full_segment="$2"

  # Always-safe commands
  if [[ "$SAFE_LOOKUP" == *" $cmd_name "* ]]; then
    return 0
  fi

  # Extract args (everything after the command name)
  local args="${full_segment#* }"
  [[ "$args" == "$full_segment" ]] && args=""

  # Subcommand-gated commands
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
    helm)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$HELM_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    terraform)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$TERRAFORM_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    docker)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$DOCKER_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    istioctl)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$ISTIOCTL_SAFE" == *" $subcmd "* ]] && return 0
      ;;
    tmux)
      subcmd=$(first_positional "$args")
      [[ -n "$subcmd" && "$TMUX_SAFE" == *" $subcmd "* ]] && return 0
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

# Remove redirections (2>/dev/null, >/tmp/file, 2>&1, </input)
cleaned=$(echo "$COMMAND" | sed -E 's/[0-9]*>[&]?[^ ]*//g; s/2>&1//g; s/<[^ ]*//g')

# Split on shell operators (|, &&, ||, ;) while respecting quoted strings.
# awk reads the entire input as one record (RS="\003") so that newlines
# inside quoted strings (e.g. multi-line commit messages) are preserved.
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
  # Trim whitespace
  trimmed=$(echo "$segment" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')

  [[ -z "$trimmed" ]] && continue

  # Strip leading env var assignments (e.g., AWS_PROFILE=foo command ...)
  while [[ "$trimmed" =~ ^[A-Za-z_][A-Za-z0-9_]*=([^\ ]*) ]]; do
    trimmed=$(echo "$trimmed" | sed 's/^[A-Za-z_][A-Za-z0-9_]*=[^ ]* *//')
  done

  [[ -z "$trimmed" ]] && continue

  # Get the command name (first word)
  first_word=$(echo "$trimmed" | awk '{print $1}')

  [[ -z "$first_word" ]] && continue

  # Allow claude skill scripts (project-local and global)
  if [[ "$first_word" == */.claude/skills/* ]]; then
    continue
  fi

  # Handle full paths (e.g., /usr/bin/find -> find)
  cmd_name=$(basename "$first_word")

  # Check safety (command + subcommand)
  if ! is_safe "$cmd_name" "$trimmed"; then
    # Unsafe or unrecognized — let normal permission system handle it
    exit 0
  fi
done <<< "$segments"

# All segments are safe — auto-approve
echo '{"decision":"approve","reason":"All commands are safe"}'
