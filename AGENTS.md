# dotfile

Personal dotfile repository for managing configs across macOS and Raspberry Pi OS.

## Target environments

- macOS (local machine)
- Raspberry Pi OS (Debian-based)

## Structure

```text
dotfile/
├── AGENTS.md                  # repo-wide index and navigation guide
├── CLAUDE.md                  # symlink to `AGENTS.md` for Claude-compatible tooling
├── setup.sh                   # installs packages and symlinks zsh/tmux/nvim/ai configs
├── Dockerfile                 # legacy Alpine container setup from the old ttyd workflow
├── zsh/
│   ├── AGENTS.md              # zsh-specific index and plugin notes
│   ├── CLAUDE.md              # symlink to `zsh/AGENTS.md`
│   ├── .zshrc                 # history, prompt, key bindings, abbreviations, plugin loading
│   └── README.md              # zsh dependency and installation notes
├── tmux/
│   ├── AGENTS.md              # tmux-specific index
│   ├── CLAUDE.md              # symlink to `tmux/AGENTS.md`
│   └── .tmux.conf             # pane navigation, splits, sync-panes, terminal settings
├── nvim/
│   ├── AGENTS.md              # nvim-specific index
│   ├── CLAUDE.md              # symlink to `nvim/AGENTS.md`
│   ├── init.lua               # editor options, keymaps, plugins, and gopls setup
│   └── lazy-lock.json         # lazy.nvim plugin version lockfile
└── ai/
    ├── AGENTS.md              # AI config index and shared tool-use instructions
    ├── CLAUDE.md              # symlink to `ai/AGENTS.md`
    ├── setup.py               # merges and links Claude/Codex config into local user dirs
    ├── docs/                  # local reference notes for AI sessions; open `ai/docs/AGENTS.md` first to choose the right document when present
    ├── claude/
    │   ├── mcp.json           # Claude MCP server definitions
    │   └── settings.json      # Claude permissions and hook overlay
    ├── codex/
    │   ├── config.toml        # Codex feature flags and MCP settings
    │   └── hooks.json         # Codex hook registration
    ├── hooks/
    │   ├── claude-approve-safe-bash.sh # auto-approves safe read-only Bash for Claude
    │   └── codex-block-dangerous-bash.sh # blocks destructive Bash for Codex
    └── skills/
        ├── compush/
        │   ├── SKILL.md       # commit/push workflow skill instructions
        │   └── run.sh         # helper entrypoint for the compush skill
        └── planner/
            └── SKILL.md       # execution-plan authoring skill instructions
```

## Notes

- Directory-specific notes should live in each directory's local `AGENTS.md`
- This root file should keep top-level navigation breadcrumbs so agents know which local `AGENTS.md` to open next
