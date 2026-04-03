#!/usr/bin/env python3

from __future__ import annotations

import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
AI_ROOT = ROOT / "ai"


def backup_path(path: Path) -> None:
    backup = path.with_name(f"{path.name}.bak.{datetime.now().strftime('%Y%m%d%H%M%S')}")
    path.rename(backup)
    print(f"    backed up {path} -> {backup}")


def link(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.is_symlink():
        dst.unlink()
    elif dst.exists():
        backup_path(dst)
    dst.symlink_to(src, target_is_directory=src.is_dir())
    print(f"    {dst} -> {src}")


def unique_list(items: list[object]) -> list[object]:
    result: list[object] = []
    for item in items:
        if item not in result:
            result.append(item)
    return result


def deep_merge(base: object, overlay: object) -> object:
    if isinstance(base, dict) and isinstance(overlay, dict):
        merged = dict(base)
        for key, value in overlay.items():
            if key in merged:
                merged[key] = deep_merge(merged[key], value)
            else:
                merged[key] = value
        return merged
    if isinstance(base, list) and isinstance(overlay, list):
        return unique_list([*base, *overlay])
    return overlay


def merge_json(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        shutil.copy2(src, dst)
        print(f"    created {dst}")
        return
    merged = deep_merge(json.loads(dst.read_text()), json.loads(src.read_text()))
    dst.write_text(json.dumps(merged, indent=2) + "\n")
    print(f"    merged into {dst}")


def merge_claude_settings(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        shutil.copy2(src, dst)
        print(f"    created {dst}")
        return

    base = json.loads(dst.read_text())
    overlay = json.loads(src.read_text())
    merged = deep_merge(base, overlay)

    overlay_pre_tool_use = overlay.get("hooks", {}).get("PreToolUse")
    if overlay_pre_tool_use is not None:
        merged.setdefault("hooks", {})["PreToolUse"] = overlay_pre_tool_use

    dst.write_text(json.dumps(merged, indent=2) + "\n")
    print(f"    merged into {dst}")


def section_pattern(name: str) -> re.Pattern[str]:
    return re.compile(rf"(?ms)^\[{re.escape(name)}\]\n(?P<body>(?:(?!^\[).*\n?)*)")


def upsert_scalar(text: str, section: str, key: str, value_line: str) -> str:
    match = section_pattern(section).search(text)
    if match:
        body = match.group("body")
        key_pattern = re.compile(rf"(?m)^{re.escape(key)}\s*=.*$")
        if key_pattern.search(body):
            new_body = key_pattern.sub(value_line, body)
        else:
            suffix = "" if body.endswith("\n") or body == "" else "\n"
            new_body = body + suffix + value_line + "\n"
        return text[: match.start("body")] + new_body + text[match.end("body") :]
    suffix = "" if text.endswith("\n") or not text else "\n"
    return text + suffix + f"[{section}]\n{value_line}\n"


def extract_section(text: str, section: str) -> str | None:
    match = section_pattern(section).search(text)
    if not match:
        return None
    return match.group(0).rstrip() + "\n"


def replace_section(text: str, section: str, new_section: str) -> str:
    pattern = re.compile(rf"(?ms)^\[{re.escape(section)}\]\n(?:(?!^\[).*\n?)*")
    replacement = new_section.rstrip() + "\n"
    if pattern.search(text):
        return pattern.sub(replacement, text, count=1)
    suffix = "" if text.endswith("\n") or not text else "\n"
    return text + suffix + replacement


def merge_codex_config(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    if not dst.exists():
        shutil.copy2(src, dst)
        print(f"    created {dst}")
        return

    src_text = src.read_text()
    dst_text = dst.read_text()

    merged = upsert_scalar(dst_text, "features", "codex_hooks", "codex_hooks = true")
    scrapling_section = extract_section(src_text, "mcp_servers.scrapling")
    if scrapling_section:
        merged = replace_section(merged, "mcp_servers.scrapling", scrapling_section)

    dst.write_text(merged)
    print(f"    merged into {dst}")


def main() -> None:
    home = Path.home()
    (home / ".claude").mkdir(parents=True, exist_ok=True)
    (home / ".codex").mkdir(parents=True, exist_ok=True)
    (home / ".agents").mkdir(parents=True, exist_ok=True)

    link(AI_ROOT / "AGENTS.md", home / ".claude" / "CLAUDE.md")
    link(AI_ROOT / "AGENTS.md", home / ".codex" / "AGENTS.md")

    for skill_dir in (AI_ROOT / "skills").iterdir():
        if skill_dir.is_dir():
            link(skill_dir, home / ".claude" / "skills" / skill_dir.name)
            link(skill_dir, home / ".agents" / "skills" / skill_dir.name)

    link(
        AI_ROOT / "hooks" / "claude-approve-safe-bash.sh",
        home / ".claude" / "hooks" / "claude-approve-safe-bash.sh",
    )
    link(
        AI_ROOT / "hooks" / "codex-block-dangerous-bash.sh",
        home / ".codex" / "hooks" / "codex-block-dangerous-bash.sh",
    )

    merge_claude_settings(AI_ROOT / "claude" / "settings.json", home / ".claude" / "settings.json")
    merge_json(AI_ROOT / "claude" / "mcp.json", home / ".claude.json")
    merge_codex_config(AI_ROOT / "codex" / "config.toml", home / ".codex" / "config.toml")
    link(AI_ROOT / "codex" / "hooks.json", home / ".codex" / "hooks.json")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, json.JSONDecodeError) as exc:
        print(f"    ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
