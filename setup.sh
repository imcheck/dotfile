#!/bin/bash
set -e

DOTFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=$(uname -m)

usage() {
  echo "Usage: $0 [zsh|tmux|nvim|all]"
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
  zsh)  setup_zsh ;;
  tmux) setup_tmux ;;
  nvim) setup_nvim ;;
  all)
    setup_zsh
    setup_tmux
    setup_nvim
    ;;
  *) usage ;;
esac

echo ""
echo "Done."
