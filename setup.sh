#!/bin/bash
set -e

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=$(uname -m)
OS=$(uname -s)

usage() {
  echo "Usage: $0 [zsh|tmux|nvim|ai|all]"
  exit 1
}

link() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    local backup="${dst}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    echo "    backed up $dst -> $backup"
  fi
  ln -s "$src" "$dst"
  echo "    $dst -> $src"
}

setup_zsh() {
  echo "==> [zsh]"

  if command -v zsh &> /dev/null; then
    echo "    zsh already installed, skipping"
  else
    if [ "$OS" = "Darwin" ]; then
      brew install zsh zsh-syntax-highlighting
    else
      sudo apt update
      sudo apt install -y zsh zsh-syntax-highlighting
    fi
  fi

  if [ "$OS" = "Darwin" ]; then
    local abbr_dir
    abbr_dir="$(brew --prefix)/share/zsh-abbr"
    if [ -d "$abbr_dir" ]; then
      echo "    zsh-abbr already installed, skipping"
    else
      git clone --recurse-submodules https://github.com/olets/zsh-abbr "$abbr_dir"
    fi
  else
    if [ -d "/usr/share/zsh-abbr" ]; then
      echo "    zsh-abbr already installed, skipping"
    else
      sudo git clone --recurse-submodules https://github.com/olets/zsh-abbr /usr/share/zsh-abbr
    fi
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
    if [ "$OS" = "Darwin" ]; then
      brew install tmux
    else
      sudo apt update
      sudo apt install -y tmux
    fi
  fi

  link "$DOTFILE_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
}

setup_ai() {
  echo "==> [ai]"
  python3 "$DOTFILE_DIR/ai/setup.py"
}

setup_nvim() {
  echo "==> [nvim]"

  if command -v nvim &> /dev/null; then
    echo "    neovim already installed, skipping"
  else
    if [ "$OS" = "Darwin" ]; then
      brew install neovim
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
        sudo rm -rf /opt/nvim
        sudo mv "$NVIM_DIR" /opt/nvim
        sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
        rm "$NVIM_ARCHIVE"
      fi
    fi
  fi

  mkdir -p "$HOME/.config/nvim"
  for f in "$DOTFILE_DIR/nvim/"*; do
    [ -e "$f" ] && link "$f" "$HOME/.config/nvim/$(basename "$f")"
  done
}

case "${1:-}" in
  zsh)    setup_zsh ;;
  tmux)   setup_tmux ;;
  nvim)   setup_nvim ;;
  ai)     setup_ai ;;
  all)
    setup_zsh
    setup_tmux
    setup_nvim
    setup_ai
    ;;
  *) usage ;;
esac

echo ""
echo "Done."
