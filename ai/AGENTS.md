# Global Instructions

## Scope

- This file is an assistant overlay managed by `setup.py`, not a repository navigation guide.
- Write and interpret the instructions here so they work for both Claude and Codex.

## Files

- `setup.py` installs or merges the repo's AI assistant config into local user directories
- `docs/` contains shared session reference documents for installed agents
- `claude/` contains Claude Code overlays such as MCP server definitions and settings
- `codex/` contains Codex MCP settings
- `hooks/` contains the Claude notification hook (macOS desktop notifications; Linux desktop notifications when available, otherwise a terminal bell)
- `skills/` contains shared skill definitions and helper scripts

## Install Targets

- Current `setup.py` behavior links this file into `~/.claude/AGENTS.md` and `~/.codex/AGENTS.md`
- Claude skills are linked into `~/.claude/skills/`
- Codex skills are linked into `~/.agents/skills/`
- `~/.codex/` stores Codex config and the AGENTS overlay; it is not the Codex skill execution path

## Shared and Machine-Local Settings

- Keep shared settings on the same branch for macOS and Linux; select OS-specific commands at runtime
- `codex/config.toml` manages terminal notifications and the Scrapling MCP server; `setup.py` preserves other local settings, including models, project paths, status lines, and hooks
- An existing `features.codex_hooks` value migrates to `features.hooks` unless the new key is already set; setup does not force hooks on
- Keep machine-specific shell settings in `~/zsh/*.zsh`, and company-only Ghostty settings in the optional `portone` file next to the installed Ghostty config
- Re-run `bash setup.sh ai` after pulling AI setup changes so merged configs and obsolete managed links are updated

## Validation

- Run `python3 -B -m unittest discover -s ai/tests -v` from the repository root (Python 3.11+ for the test suite's TOML parser)
- Tests install into temporary directories and use fake notification commands; they do not modify the real home directory or send desktop notifications

## Required Initialization

- At session start, read the docs index to learn which shared reference documents are available. Claude uses `~/.claude/docs/AGENTS.md`; Codex uses `~/.agents/docs/AGENTS.md`.
- Treat it as an index of optional session documents. Read specific files under the same docs directory only when they are relevant to the task or user request.

## Tool preferences

- 웹 문서 수집이 필요하면 가능한 경우 기본 웹 fetch 계열 도구보다 scrapling의 `fetch`를 우선 사용할 것. `fetch`가 실패하면 `stealthy_fetch`를 사용할 것.
- scrapling 사용 시 `extraction_type`은 `"text"`를 기본으로 할 것.
- 본문이 너무 길면 `css_selector`로 본문 영역만 추출할 것. `article`, `main`, `[role="main"]` 순으로 우선 시도할 것.
