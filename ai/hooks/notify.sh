#!/bin/sh
# Claude Code Notification hook -> macOS desktop notification.
# terminal-notifier가 있으면: 클릭 시 Ghostty를 활성화하고, 알림을 보낸 tmux pane으로 포커스한다.
# 없으면: 기존 osascript 알림으로 폴백 (클릭 동작 없음).
# tmux/ghostty 안에서 OSC 이스케이프가 안 먹는 문제를 우회하기 위해 직접 알림을 띄운다.

payload=$(cat)

# JSON에서 message/title/cwd 추출 (jq 있으면 사용, 없으면 sed 폴백)
if command -v jq >/dev/null 2>&1; then
  msg=$(printf '%s' "$payload" | jq -r '.message // empty')
  title=$(printf '%s' "$payload" | jq -r '.title // empty')
  cwd=$(printf '%s' "$payload" | jq -r '.cwd // empty')
else
  msg=$(printf '%s' "$payload" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  title=$(printf '%s' "$payload" | sed -n 's/.*"title"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
  cwd=$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')
fi

[ -z "$msg" ] && msg="Claude Code가 입력을 기다립니다"
[ -z "$title" ] && title="Claude Code"
[ -n "$cwd" ] && subtitle=$(basename "$cwd") || subtitle=""

TN=$(command -v terminal-notifier || command -v /opt/homebrew/bin/terminal-notifier)

if [ -n "$TN" ]; then
  # 클릭 시 실행할 커맨드. 기본은 Ghostty 활성화만.
  click="open -b com.mitchellh.ghostty"

  # tmux 안에서 실행됐다면(훅은 claude를 띄운 pane의 환경을 물려받는다)
  # 알림 시점에 세션:윈도우를 해석해 클릭 커맨드에 박아둔다.
  if [ -n "$TMUX" ] && [ -n "$TMUX_PANE" ]; then
    target=$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}' 2>/dev/null)
    if [ -n "$target" ]; then
      esc_sq() { printf '%s' "$1" | sed "s/'/'\\\\''/g"; }
      t=$(esc_sq "$target")
      p=$(esc_sq "$TMUX_PANE")
      # 클릭 시점엔 tmux 밖에서 실행되므로 switch-client에 클라이언트를 명시해야 한다.
      click="open -b com.mitchellh.ghostty; c=\$(tmux list-clients -F '#{client_name}' | head -1); [ -n \"\$c\" ] && tmux switch-client -c \"\$c\" -t '$t'; tmux select-window -t '$t'; tmux select-pane -t '$p'"
    fi
  fi

  # terminal-notifier는 '['로 시작하는 메시지를 옵션으로 오파싱하는 이슈가 있어 공백을 붙인다
  case $msg in \[*) msg=" $msg" ;; esac

  if [ -n "$subtitle" ]; then
    "$TN" -title "$title" -subtitle "$subtitle" -message "$msg" -sound default \
      -group "claude-${TMUX_PANE:-default}" -execute "$click" >/dev/null 2>&1
  else
    "$TN" -title "$title" -message "$msg" -sound default \
      -group "claude-${TMUX_PANE:-default}" -execute "$click" >/dev/null 2>&1
  fi
  exit 0
fi

# ---- 폴백: osascript (terminal-notifier 미설치 시. 클릭 포커싱 불가) ----
esc() { printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'; }
msg=$(esc "$msg"); title=$(esc "$title"); subtitle=$(esc "$subtitle")

if [ -n "$subtitle" ]; then
  osascript -e "display notification \"$msg\" with title \"$title\" subtitle \"$subtitle\" sound name \"default\"" >/dev/null 2>&1
else
  osascript -e "display notification \"$msg\" with title \"$title\" sound name \"default\"" >/dev/null 2>&1
fi
exit 0
