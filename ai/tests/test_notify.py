import fcntl
import json
import os
import pty
import select
import shutil
import subprocess
import tempfile
import termios
import unittest
from pathlib import Path


NOTIFY = Path(__file__).resolve().parents[1] / "hooks/notify.sh"


class NotifyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="dotfile-notify-test-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "calls"
        self.env = os.environ.copy()
        for key in ("DISPLAY", "WAYLAND_DISPLAY", "TMUX", "TMUX_PANE"):
            self.env.pop(key, None)
        self.env.update(PATH=str(self.bin), TEST_CALLS=str(self.log), TEST_OS="Linux",
                        TEST_NOTIFY_RESULT="0", TEST_MAC_RESULT="0", TEST_APPLESCRIPT_RESULT="0")
        for name in ("cat", "sed", "basename"):
            (self.bin / name).symlink_to(shutil.which(name))
        self.command("uname", 'printf "%s\\n" "$TEST_OS"\n')
        self.command("notify-send", 'printf "notify-send\\n" >> "$TEST_CALLS"\n'
                     'printf "%s\\n" "$@" >> "$TEST_CALLS"\nexit "$TEST_NOTIFY_RESULT"\n')
        self.command("terminal-notifier", 'printf "terminal-notifier\\n" >> "$TEST_CALLS"\n'
                     'printf "%s\\n" "$@" >> "$TEST_CALLS"\nexit "$TEST_MAC_RESULT"\n')
        self.command("osascript", 'printf "osascript\\n" >> "$TEST_CALLS"\n'
                     'printf "%s\\n" "$@" >> "$TEST_CALLS"\nexit "$TEST_APPLESCRIPT_RESULT"\n')

    def command(self, name, body):
        path = self.bin / name
        path.write_text("#!/bin/sh\n" + body)
        path.chmod(0o755)

    def run_hook(self, tty=False, payload=None):
        opts = {"start_new_session": True}
        master = slave = None
        if tty:
            master, slave = pty.openpty()

            def attach_terminal():
                os.setsid()
                fcntl.ioctl(slave, termios.TIOCSCTTY, 0)

            opts = {"preexec_fn": attach_terminal, "pass_fds": (slave,)}
        try:
            result = subprocess.run(["/bin/sh", str(NOTIFY)],
                                    input=json.dumps(payload or {"message": "[ready]", "title": "Claude Code", "cwd": "/work/demo"}).encode(),
                                    env=self.env, capture_output=True, timeout=5, **opts)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stdout, b"")
            self.assertEqual(result.stderr, b"")
            bell = b""
            if tty and select.select([master], [], [], 1)[0]:
                bell = os.read(master, 1024)
            return self.log.read_text() if self.log.exists() else "", bell
        finally:
            if slave is not None:
                os.close(slave)
                os.close(master)

    def test_linux_headless_without_tty_exits_silently(self):
        calls, _ = self.run_hook()
        self.assertEqual(calls, "")

    def test_linux_headless_sends_bell_to_controlling_terminal(self):
        calls, bell = self.run_hook(tty=True)
        self.assertEqual(calls, "")
        self.assertEqual(bell, b"\a")

    def test_linux_graphical_notification(self):
        for variable, value in (("DISPLAY", ":1"), ("WAYLAND_DISPLAY", "wayland-0")):
            with self.subTest(variable=variable):
                self.env[variable] = value
                calls, _ = self.run_hook()
                self.assertIn("notify-send\n", calls)
                self.assertIn("demo: [ready]", calls)
                self.assertNotIn("terminal-notifier", calls)
                self.assertNotIn("osascript", calls)
                self.env.pop(variable)
                self.log.unlink()

    def test_linux_desktop_failure_falls_back_to_bell(self):
        self.env.update(DISPLAY=":1", TEST_NOTIFY_RESULT="1")
        calls, bell = self.run_hook(tty=True)
        self.assertIn("notify-send\n", calls)
        self.assertNotIn("osascript", calls)
        self.assertEqual(bell, b"\a")

    def test_linux_missing_desktop_notifier_falls_back_to_bell(self):
        self.env["DISPLAY"] = ":1"
        (self.bin / "notify-send").unlink()
        calls, bell = self.run_hook(tty=True)
        self.assertEqual(calls, "")
        self.assertEqual(bell, b"\a")

    def test_macos_notifier_keeps_click_focus_and_tmux_target(self):
        self.env.update(TEST_OS="Darwin", TMUX="test", TMUX_PANE="%2")
        self.command("tmux", 'printf "session:3\\n"\n')
        calls, _ = self.run_hook()
        self.assertIn("terminal-notifier\n", calls)
        self.assertIn("open -b com.mitchellh.ghostty", calls)
        self.assertIn("tmux select-window -t 'session:3'", calls)
        self.assertIn("tmux select-pane -t '%2'", calls)
        self.assertIn(" [ready]", calls)
        self.assertNotIn("osascript", calls)

    def test_macos_notifier_failure_uses_applescript(self):
        self.env.update(TEST_OS="Darwin", TEST_MAC_RESULT="1")
        calls, _ = self.run_hook()
        self.assertIn("terminal-notifier\n", calls)
        self.assertIn("osascript\n", calls)
        self.assertIn('subtitle "demo"', calls)
        self.assertNotIn("notify-send", calls)

    def test_macos_all_notifiers_fail_uses_bell(self):
        self.env.update(TEST_OS="Darwin", TEST_MAC_RESULT="1", TEST_APPLESCRIPT_RESULT="1")
        _, bell = self.run_hook(tty=True)
        self.assertEqual(bell, b"\a")


if __name__ == "__main__":
    unittest.main()
