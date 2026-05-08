#!/usr/bin/env bash
# PostToolUse Bash hook: fire a notification only on important events.
#
# Notifies on:
#   - PR opened:    `gh pr create ...` exited 0
#   - Tests failed: a known test runner exited non-zero
#
# Silent otherwise. Designed for users running many concurrent agents who
# don't want a chime on every Stop.

set -uo pipefail

NOTIFY="$HOME/.claude/hooks/notify.sh"
[ -x "$NOTIFY" ] || exit 0

INPUT="$(cat)"

COMMAND="$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)"
EXIT_CODE="$(echo "$INPUT" | jq -r '.tool_response.exit_code // .tool_response.exitCode // .exit_code // empty' 2>/dev/null)"
STDOUT="$(echo "$INPUT"   | jq -r '.tool_response.stdout    // .stdout    // empty' 2>/dev/null)"

[ -z "$COMMAND" ] && exit 0

# --- PR opened ---------------------------------------------------------------
if echo "$COMMAND" | grep -qE '(^|[[:space:]&;|])gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)'; then
  if [ -z "$EXIT_CODE" ] || [ "$EXIT_CODE" = "0" ]; then
    URL="$(printf '%s\n' "$STDOUT" | grep -oE 'https://github\.com/[^[:space:]]+/pull/[0-9]+' | head -1)"
    MSG="PR opened"
    [ -n "$URL" ] && MSG="PR opened: $URL"
    "$NOTIFY" "Claude Code" "$MSG"
  fi
  exit 0
fi

# --- Tests failed ------------------------------------------------------------
TEST_RE='(^|[[:space:]&;|])((npm|pnpm|yarn|bun)([[:space:]]+run)?[[:space:]]+test|bun[[:space:]]+test|vitest|pytest|jest|cargo[[:space:]]+test|go[[:space:]]+test|just[[:space:]]+test)([[:space:]]|$)'
if echo "$COMMAND" | grep -qE "$TEST_RE"; then
  if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" != "0" ]; then
    "$NOTIFY" "Claude Code" "Tests failed (exit $EXIT_CODE)"
  fi
  exit 0
fi

exit 0
