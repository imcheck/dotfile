#!/bin/bash
set -e

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=$(uname -m)

usage() {
  echo "Usage: $0 [zsh|tmux|nvim|claude|all]"
  exit 1
}

link() {
  local src="$1"
  local dst="$2"
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "    $dst already exists, skipping"
  else
    ln -sf "$src" "$dst"
    echo "    $dst -> $src"
  fi
}

merge_json() {
  local src="$1" dst="$2"
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"
    echo "    created $dst"
    return
  fi
  jq -s '
    def deepmerge:
      if length == 0 then null
      elif length == 1 then .[0]
      else
        reduce .[] as $item ({}; . as $base |
          $item | to_entries | reduce .[] as $e ($base;
            if ($e.value | type) == "object" and (.[$e.key] | type) == "object"
            then .[$e.key] = ([.[$e.key], $e.value] | deepmerge)
            elif ($e.value | type) == "array" and (.[$e.key] | type) == "array"
            then .[$e.key] = (.[$e.key] + $e.value | reduce .[] as $x ([]; if (. | index($x)) then . else . + [$x] end))
            else .[$e.key] = $e.value
            end
          )
        )
      end;
    deepmerge
  ' "$dst" "$src" > "${dst}.tmp" && mv "${dst}.tmp" "$dst"
  echo "    merged into $dst"
}

setup_zsh() {
  echo "==> [zsh]"

  if command -v zsh &> /dev/null; then
    echo "    zsh already installed, skipping"
  else
    sudo apt update
    sudo apt install -y zsh zsh-syntax-highlighting
  fi

  if [ -d "/usr/share/zsh-abbr" ]; then
    echo "    zsh-abbr already installed, skipping"
  else
    sudo git clone --recurse-submodules https://github.com/olets/zsh-abbr /usr/share/zsh-abbr
  fi

  link "$DOTFILE_DIR/zsh/.zshrc" "$HOME/.zshrc"

  if [ "$SHELL" = "$(which zsh)" ]; then
    echo "    default shell already zsh, skipping"
  else
    chsh -s "$(which zsh)"
    echo "    default shell changed to zsh. Re-login to apply."
  fi
}

setup_tmux() {
  echo "==> [tmux]"

  if command -v tmux &> /dev/null; then
    echo "    tmux already installed, skipping"
  else
    sudo apt update
    sudo apt install -y tmux
  fi

  link "$DOTFILE_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

setup_claude() {
  echo "==> [claude]"

  if ! command -v jq &> /dev/null; then
    echo "    ERROR: jq is required for claude setup. Install it first."
    return 1
  fi

  mkdir -p "$HOME/.claude"
  link "$DOTFILE_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
  link "$DOTFILE_DIR/claude/skills" "$HOME/.claude/skills"
  link "$DOTFILE_DIR/claude/hooks" "$HOME/.claude/hooks"
  merge_json "$DOTFILE_DIR/claude/settings.json" "$HOME/.claude/settings.json"
  merge_json "$DOTFILE_DIR/claude/mcp.json" "$HOME/.claude.json"
}

setup_nvim() {
  echo "==> [nvim]"

  if command -v nvim &> /dev/null; then
    echo "    neovim already installed, skipping"
  else
    if [ "$ARCH" = "aarch64" ]; then
      NVIM_ARCHIVE="nvim-linux-arm64.tar.gz"
      NVIM_DIR="nvim-linux-arm64"
    elif [ "$ARCH" = "x86_64" ]; then
      NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
      NVIM_DIR="nvim-linux-x86_64"
    else
      echo "    Unsupported architecture: $ARCH, falling back to apt..."
      sudo apt update && sudo apt install -y neovim
      NVIM_ARCHIVE=""
    fi

    if [ -n "$NVIM_ARCHIVE" ]; then
      curl -LO "https://github.com/neovim/neovim/releases/latest/download/${NVIM_ARCHIVE}"
      tar xzf "$NVIM_ARCHIVE"
      sudo mv "$NVIM_DIR" /opt/nvim
      sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
      rm "$NVIM_ARCHIVE"
    fi
  fi

  mkdir -p "$HOME/.config"
  link "$DOTFILE_DIR/nvim" "$HOME/.config/nvim"
}

case "${1:-}" in
  zsh)    setup_zsh ;;
  tmux)   setup_tmux ;;
  nvim)   setup_nvim ;;
  claude) setup_claude ;;
  all)
    setup_zsh
    setup_tmux
    setup_nvim
    setup_claude
    ;;
  *) usage ;;
esac

echo ""
echo "Done."
