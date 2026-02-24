# dotfile

Repository for managing dotfiles to be configured inside the desk container.
Used by [imcheck/ttyd](https://github.com/imcheck/ttyd) to set up the container environment.

## Structure

```
dotfile/
├── zsh/.zshrc      # zsh config (history, prompt, abbreviations)
├── tmux/.tmux.conf # tmux config (keybindings, pane management)
├── Dockerfile      # local testing
└── AGENTS.md
```

## zsh plugins

- [zsh-abbr](https://github.com/olets/zsh-abbr) - command abbreviations (auto-expand on space/enter)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) - command syntax highlighting

## Notes

- Config files are organized by tool in separate directories (e.g. `zsh/`, `nvim/`)
- The Dockerfile in this repo is for local testing only; the production image lives in imcheck/ttyd
