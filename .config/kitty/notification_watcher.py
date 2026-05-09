"""
Kitty watcher: dismiss any pending Claude Code notification for a window
when that window receives focus.

Notifications are tagged with `-group kitty-window-<id>` by ~/.claude/hooks/notify.sh.
On focus, we ask terminal-notifier to remove that group.
"""

import os
import subprocess

NOTIFIER_CANDIDATES = (
    os.path.expanduser("~/.claude/cache/Claude-Notifier.app/Contents/MacOS/terminal-notifier"),
    "/opt/homebrew/bin/terminal-notifier",
    "/usr/local/bin/terminal-notifier",
)


def _notifier():
    for path in NOTIFIER_CANDIDATES:
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return None


def on_focus_change(boss, window, data):
    if not data.get("focused"):
        return
    bin_path = _notifier()
    if bin_path is None:
        return
    try:
        subprocess.Popen(
            [bin_path, "-remove", f"kitty-window-{window.id}"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            close_fds=True,
        )
    except Exception:
        pass
