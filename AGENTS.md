# dotfile

Personal dotfile repository for managing configs across macOS and Raspberry Pi OS.

## Target environments

- macOS (local machine)
- Raspberry Pi OS (Debian-based)

## Structure

```
dotfile/
├── zsh/.zshrc      # zsh config (history, prompt, abbreviations)
├── tmux/.tmux.conf # tmux config (keybindings, pane management)
├── nvim/           # neovim config
└── ai/             # AI coding assistant configs (Claude Code, Codex)
    ├── AGENTS.md   # shared global instructions
    ├── skills/     # shared skills
    ├── hooks/      # shared hook scripts
    ├── claude/     # Claude Code overlay (settings, mcp)
    └── codex/      # Codex overlay (hooks.json, config.toml)
```

## zsh plugins

- [zsh-abbr](https://github.com/olets/zsh-abbr) - command abbreviations (auto-expand on space/enter)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - command syntax highlighting

## Notes

- Config files are organized by tool in separate directories (e.g. `zsh/`, `nvim/`)
- Dockerfile is no longer used (previously for ttyd container setup)
