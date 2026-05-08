#!/usr/bin/env bash
# Stop hook: notify when Claude's prompt becomes available again.
#
# Skips the notification when the originating kitty tab is already the
# frontmost focused window — no point pinging you about a tab you're
# looking at. Keeps the workflow useful with many concurrent agents.

set -uo pipefail

NOTIFY="$HOME/.claude/hooks/notify.sh"
[ -x "$NOTIFY" ] || exit 0

KITTEN=/Applications/kitty.app/Contents/MacOS/kitten
SOCKET="${KITTY_LISTEN_ON:-}"
WIN_ID="${KITTY_WINDOW_ID:-}"

if [ -n "$WIN_ID" ] && [ -n "$SOCKET" ] && [ -x "$KITTEN" ]; then
  FRONT_APP="$(/usr/bin/osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)"
  if [ "$FRONT_APP" = "kitty" ]; then
    FOCUSED_ID="$("$KITTEN" @ --to "$SOCKET" ls 2>/dev/null \
      | /usr/bin/jq -r '.[] | select(.is_focused) | .tabs[] | select(.is_focused) | .windows[] | select(.is_focused) | .id' \
      | head -1)"
    if [ "$FOCUSED_ID" = "$WIN_ID" ]; then
      exit 0
    fi
  fi
fi

exec "$NOTIFY" "Claude Code" "Ready"
