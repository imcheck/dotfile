import contextlib
import io
import json
import runpy
import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest.mock import patch


AI_ROOT = Path(__file__).resolve().parents[1]
SETUP = runpy.run_path(str(AI_ROOT / "setup.py"))


class SetupTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfile-setup-test-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)

    def write(self, name, text):
        path = self.home / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def install(self):
        with patch.object(Path, "home", return_value=self.home), contextlib.redirect_stdout(io.StringIO()):
            SETUP["main"]()

    def test_hook_migration_preserves_boolean_and_new_key_precedence(self):
        cases = (
            ("codex_hooks = true", True),
            ("codex_hooks = false", False),
            ("  codex_hooks = false # machine preference", False),
            ("hooks = false", False),
            ("codex_hooks = true\n  hooks = false", False),
            ("codex_hooks = false\nhooks = true", True),
            ("other = true", None),
        )
        for body, expected in cases:
            with self.subTest(body=body):
                target = self.write("codex.toml", f"[features]\n{body}\n")
                with contextlib.redirect_stdout(io.StringIO()):
                    SETUP["merge_codex_config"](AI_ROOT / "codex/config.toml", target)
                    first = target.read_text()
                    SETUP["merge_codex_config"](AI_ROOT / "codex/config.toml", target)
                config = tomllib.loads(target.read_text())
                self.assertEqual(config["features"].get("hooks"), expected)
                self.assertNotIn("codex_hooks", config["features"])
                self.assertEqual(target.read_text(), first)

    def test_reinstallation_preserves_personal_settings_and_cleans_managed_hooks(self):
        codex = self.write(".codex/config.toml", '''model = "personal-model"
[features]
codex_hooks = false
[tui]
status_line = ["current-dir", "git-branch"]
[projects."/personal/project"]
trust_level = "trusted"
[mcp_servers.personal]
command = "personal-mcp"
[mcp_servers.scrapling.tools.fetch]
approval_mode = "approve"
[hooks.state]
marker = "local-state"
''')
        claude = self.write(".claude/settings.json", json.dumps({
            "theme": "dark",
            "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [
                {"type": "command", "command": "~/.claude/hooks/claude-approve-safe.sh"},
                {"type": "command", "command": str(self.home / ".claude/hooks/claude-approve-safe.sh")},
                {"type": "command", "command": "personal-hook", "timeout": 7},
            ]}]},
        }))
        claude_mcp = self.write(".claude.json", json.dumps({
            "mcpServers": {"personal": {"command": "personal-mcp"}},
            "personalOption": True,
        }))
        obsolete = (
            (".claude/hooks/claude-approve-safe.sh", "hooks/claude-approve-safe.sh"),
            (".codex/hooks.json", "codex/hooks.json"),
            (".codex/hooks/codex-block-dangerous-bash.sh", "hooks/codex-block-dangerous-bash.sh"),
        )
        for installed, source in obsolete:
            path = self.home / installed
            path.parent.mkdir(parents=True, exist_ok=True)
            path.symlink_to(AI_ROOT / source)

        self.install()
        first = [p.read_text() for p in (codex, claude, claude_mcp)]
        self.install()
        self.assertEqual(first, [p.read_text() for p in (codex, claude, claude_mcp)])
        config = tomllib.loads(codex.read_text())
        self.assertEqual(config["model"], "personal-model")
        self.assertFalse(config["features"]["hooks"])
        self.assertEqual(config["tui"]["status_line"], ["current-dir", "git-branch"])
        self.assertEqual(config["projects"]["/personal/project"]["trust_level"], "trusted")
        self.assertEqual(config["hooks"]["state"]["marker"], "local-state")
        self.assertEqual(config["mcp_servers"]["personal"]["command"], "personal-mcp")
        self.assertEqual(config["mcp_servers"]["scrapling"]["tools"]["fetch"]["approval_mode"], "approve")
        self.assertEqual(config["tui"]["notification_method"], "bel")
        settings = json.loads(claude.read_text())
        self.assertEqual(settings["theme"], "dark")
        self.assertEqual(settings["hooks"]["PreToolUse"][0]["hooks"], [
            {"type": "command", "command": "personal-hook", "timeout": 7},
        ])
        self.assertEqual(len(settings["hooks"]["Notification"]), 1)
        mcp = json.loads(claude_mcp.read_text())
        self.assertTrue(mcp["personalOption"])
        self.assertIn("personal", mcp["mcpServers"])
        self.assertEqual((self.home / ".agents/docs").resolve(), AI_ROOT / "docs")
        self.assertEqual((self.home / ".claude/hooks/notify.sh").resolve(), AI_ROOT / "hooks/notify.sh")
        for installed, _ in obsolete:
            self.assertFalse((self.home / installed).is_symlink())

    def test_fresh_install_does_not_force_hooks(self):
        self.install()
        config = tomllib.loads((self.home / ".codex/config.toml").read_text())
        self.assertNotIn("hooks", config.get("features", {}))
        self.assertEqual(config["tui"]["notification_method"], "bel")

    def test_unmanaged_hook_link_is_preserved(self):
        path = self.home / ".codex/hooks.json"
        path.parent.mkdir(parents=True)
        path.symlink_to(self.home / "personal-hooks.json")
        self.install()
        self.assertTrue(path.is_symlink())
        self.assertEqual(path.resolve(), self.home / "personal-hooks.json")


if __name__ == "__main__":
    unittest.main()
