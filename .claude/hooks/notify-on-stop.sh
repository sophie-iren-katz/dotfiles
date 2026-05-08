#!/usr/bin/env bash
# Stop hook: notify when Claude's prompt becomes available again.
# (The focus-skip and session-label logic live in notify.sh.)

set -uo pipefail

NOTIFY="$HOME/.claude/hooks/notify.sh"
[ -x "$NOTIFY" ] || exit 0

INPUT="$(cat 2>/dev/null || true)"
TRANSCRIPT="$(printf '%s' "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)"
CWD="$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)"

LABEL=""
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  LABEL="$(grep -o '"customTitle":"[^"]*"' "$TRANSCRIPT" | tail -1 | sed 's/"customTitle":"\(.*\)"/\1/')"
fi
[ -z "$LABEL" ] && [ -n "$CWD" ] && LABEL="$(basename "$CWD")"

exec "$NOTIFY" "Claude Code" "Ready" "$LABEL"
