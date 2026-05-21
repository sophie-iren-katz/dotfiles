"""
Kitty watcher: dismiss any pending Claude Code notification for a window
when that window receives focus.

Notifications are tagged with `-group kitty-window-<id>` by ~/.claude/hooks/notify.sh.
On focus, we ask terminal-notifier to remove that group.
"""

import os
import subprocess
import shutil
import time

SENDER_BUNDLE_ID = "com.anthropic.claudefordesktop"
LOG_PATH = "/tmp/notif-watcher.log"


def _log(msg):
    try:
        with open(LOG_PATH, "a") as f:
            f.write(f"[{time.strftime('%H:%M:%S')}] {msg}\n")
    except Exception:
        pass


def _notifier():
    # Must match the binary notify.sh actually posted with — the fork
    # namespaces -group registries per posting binary, so a mismatch means
    # -remove looks under the wrong namespace and silently no-ops.
    # notify.sh resolves via `command -v terminal-notifier` against the
    # user's interactive PATH; we can't rely on PATH here because kitty
    # launched from the Dock only inherits LaunchServices' default PATH
    # (no /usr/local/bin), so shutil.which returns None.
    for path in ("/usr/local/bin/terminal-notifier", "/opt/homebrew/bin/terminal-notifier"):
        if os.path.isfile(path) and os.access(path, os.X_OK):
            return path
    return shutil.which("terminal-notifier")


def on_focus_change(boss, window, data):
    focused = data.get("focused")
    _log(f"focus change id={window.id} focused={focused}")
    if not focused:
        return
    bin_path = _notifier()
    _log(f"  notifier={bin_path} PATH={os.environ.get('PATH', '<unset>')}")
    if bin_path is None:
        _log("  abort: no terminal-notifier on PATH")
        return
    args = [
        bin_path,
        "-sender",
        SENDER_BUNDLE_ID,
        "-remove",
        f"kitty-window-{window.id}",
    ]
    _log(f"  exec: {args}")
    try:
        proc = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=5,
        )
        _log(
            f"  rc={proc.returncode} "
            f"stdout={proc.stdout.decode(errors='replace').strip()!r} "
            f"stderr={proc.stderr.decode(errors='replace').strip()!r}"
        )
    except Exception as e:
        _log(f"  error: {type(e).__name__}: {e}")
