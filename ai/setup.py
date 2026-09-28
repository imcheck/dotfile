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


def remove_managed_symlink(dst: Path, src: Path) -> None:
    if dst.is_symlink() and dst.resolve() == src:
        dst.unlink()
        print(f"    removed obsolete link {dst}")


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
    # Remove the old managed approval hook without touching user-defined hooks.
    old_hook = "claude-approve-safe.sh"
    groups = base.get("hooks", {}).get("PreToolUse", [])
    retained_groups = []
    for group in groups:
        retained_hooks = [
            hook for hook in group.get("hooks", [])
            if hook.get("command") not in {
                f"~/.claude/hooks/{old_hook}",
                str(dst.parent / "hooks" / old_hook),
            }
        ]
        if retained_hooks:
            retained_groups.append({**group, "hooks": retained_hooks})
    if "PreToolUse" in base.get("hooks", {}):
        if retained_groups:
            base["hooks"]["PreToolUse"] = retained_groups
        else:
            del base["hooks"]["PreToolUse"]
    merged = deep_merge(base, overlay)

    dst.write_text(json.dumps(merged, indent=2) + "\n")
    print(f"    merged into {dst}")


def section_pattern(name: str) -> re.Pattern[str]:
    return re.compile(rf"(?m)^\[{re.escape(name)}\]\r?\n(?P<body>[\s\S]*?)(?=^\[|\Z)")


def remove_scalar(text: str, section: str, key: str) -> str:
    match = section_pattern(section).search(text)
    if not match:
        return text
    body = match.group("body")
    new_body = re.sub(rf"(?m)^{re.escape(key)}\s*=.*\n?", "", body)
    return text[: match.start("body")] + new_body + text[match.end("body") :]


def upsert_scalar(text: str, section: str, key: str, value_line: str) -> str:
    match = section_pattern(section).search(text)
    if not match:
        suffix = "" if text.endswith("\n") or not text else "\n"
        return text + suffix + f"[{section}]\n{value_line}\n"
    body = match.group("body")
    key_pattern = re.compile(rf"(?m)^{re.escape(key)}\s*=.*$")
    if key_pattern.search(body):
        new_body = key_pattern.sub(value_line, body)
    else:
        suffix = "" if body.endswith("\n") or not body else "\n"
        new_body = body + suffix + value_line + "\n"
    return text[: match.start("body")] + new_body + text[match.end("body") :]


def extract_section(text: str, section: str) -> str | None:
    match = section_pattern(section).search(text)
    if not match:
        return None
    return match.group(0).rstrip() + "\n"


def replace_section(text: str, section: str, new_section: str) -> str:
    pattern = section_pattern(section)
    replacement = new_section.rstrip() + "\n"
    if pattern.search(text):
        return pattern.sub(lambda _: replacement, text, count=1)
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

    merged = remove_scalar(dst_text, "features", "codex_hooks")
    tui_section = extract_section(src_text, "tui")
    if tui_section:
        for key in ("notifications", "notification_method", "notification_condition"):
            value_line = re.search(rf"(?m)^{re.escape(key)}\s*=.*$", tui_section)
            if value_line:
                merged = upsert_scalar(merged, "tui", key, value_line.group(0))
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

    link(AI_ROOT / "AGENTS.md", home / ".claude" / "AGENTS.md")
    link(AI_ROOT / "AGENTS.md", home / ".codex" / "AGENTS.md")
    link(AI_ROOT / "docs", home / ".claude" / "docs")
    link(AI_ROOT / "docs", home / ".agents" / "docs")

    for skill_dir in (AI_ROOT / "skills").iterdir():
        if skill_dir.is_dir():
            link(skill_dir, home / ".claude" / "skills" / skill_dir.name)
            link(skill_dir, home / ".agents" / "skills" / skill_dir.name)

    link(
        AI_ROOT / "hooks" / "notify.sh",
        home / ".claude" / "hooks" / "notify.sh",
    )
    merge_claude_settings(AI_ROOT / "claude" / "settings.json", home / ".claude" / "settings.json")
    old_claude_hook = home / ".claude" / "hooks" / "claude-approve-safe.sh"
    remove_managed_symlink(old_claude_hook, AI_ROOT / "hooks" / "claude-approve-safe.sh")
    merge_json(AI_ROOT / "claude" / "mcp.json", home / ".claude.json")
    merge_codex_config(AI_ROOT / "codex" / "config.toml", home / ".codex" / "config.toml")
    remove_managed_symlink(home / ".codex" / "hooks.json", AI_ROOT / "codex" / "hooks.json")
    remove_managed_symlink(
        home / ".codex" / "hooks" / "codex-block-dangerous-bash.sh",
        AI_ROOT / "hooks" / "codex-block-dangerous-bash.sh",
    )


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, OSError, json.JSONDecodeError) as exc:
        print(f"    ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
