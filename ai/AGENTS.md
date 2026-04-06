# Global Instructions

## Scope

- This file is an assistant overlay managed by `setup.py`, not a repository navigation guide.
- Write and interpret the instructions here so they work for both Claude and Codex.

## Files

- `setup.py` installs or merges the repo's AI assistant config into local user directories
- `docs/` contains shared session reference documents for installed agents
- `claude/` contains Claude Code overlays such as MCP server definitions and settings
- `codex/` contains Codex overlays such as hook and MCP settings
- `hooks/` contains shell hooks for command safety
- `skills/` contains shared skill definitions and helper scripts

## Install Targets

- Current `setup.py` behavior links this file into `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`
- Claude skills are linked into `~/.claude/skills/`
- Codex skills are linked into `~/.agents/skills/`
- `~/.codex/` stores Codex config, hooks, and the AGENTS overlay; it is not the Codex skill execution path

## Required Initialization

- At session start, read the docs index to learn which shared reference documents are available. Claude uses `~/.claude/docs/AGENTS.md`; Codex uses `~/.agents/docs/AGENTS.md`.
- Treat it as an index of optional session documents. Read specific files under the same docs directory only when they are relevant to the task or user request.

## Tool preferences

- 웹 문서 수집이 필요하면 가능한 경우 기본 웹 fetch 계열 도구보다 scrapling의 `fetch`를 우선 사용할 것. `fetch`가 실패하면 `stealthy_fetch`를 사용할 것.
- scrapling 사용 시 `extraction_type`은 `"text"`를 기본으로 할 것.
- 본문이 너무 길면 `css_selector`로 본문 영역만 추출할 것. `article`, `main`, `[role="main"]` 순으로 우선 시도할 것.
