#!/usr/bin/env bash
# Click-to-focus notification for Claude Code hooks.
#
# Usage: notify.sh <title> <message> [session_label]
#
# If session_label is omitted and stdin contains the hook event JSON,
# the script extracts the latest customTitle from the transcript file
# pointed to by .transcript_path and uses it as a subtitle.
#
# Self-bootstraps a clone of terminal-notifier.app with Claude.app's icon
# (terminal-notifier's -sender bundle-ID spoofing is broken on macOS
# Sonoma+; this is the reliable workaround).
#
# On click, raises kitty.app and focuses the originating kitty window via
# $KITTY_WINDOW_ID and the kitty remote-control unix socket.

set -uo pipefail

TITLE="${1:-Claude Code}"
MESSAGE="${2:-}"
SUBTITLE="${3:-}"

# If no session label was passed and stdin is piped, try to derive one
# from the hook input JSON.
if [ -z "$SUBTITLE" ] && [ ! -t 0 ]; then
  STDIN="$(cat 2>/dev/null || true)"
  if [ -n "$STDIN" ]; then
    TRANSCRIPT="$(printf '%s' "$STDIN" | jq -r '.transcript_path // empty' 2>/dev/null)"
    if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
      SUBTITLE="$(grep -o '"customTitle":"[^"]*"' "$TRANSCRIPT" | tail -1 | sed 's/"customTitle":"\(.*\)"/\1/')"
    fi
    if [ -z "$SUBTITLE" ]; then
      CWD="$(printf '%s' "$STDIN" | jq -r '.cwd // empty' 2>/dev/null)"
      [ -n "$CWD" ] && SUBTITLE="$(basename "$CWD")"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Bootstrap a Claude-icon'd notifier app (one-time, idempotent).
# ---------------------------------------------------------------------------
TN_SRC="/opt/homebrew/opt/terminal-notifier/terminal-notifier.app"
[ -d "$TN_SRC" ] || TN_SRC="/usr/local/opt/terminal-notifier/terminal-notifier.app"
CLAUDE_APP="/Applications/Claude.app"
CLAUDE_ICON="$CLAUDE_APP/Contents/Resources/electron.icns"

CACHE_DIR="$HOME/.claude/cache"
APP="$CACHE_DIR/Claude-Notifier.app"
BIN="$APP/Contents/MacOS/terminal-notifier"
STAMP="$APP/.built-from"

needs_rebuild() {
  [ ! -x "$BIN" ] && return 0
  [ ! -f "$STAMP" ] && return 0
  [ "$(cat "$STAMP" 2>/dev/null)" != "$TN_SRC" ] && return 0
  # Rebuild if source app is newer than our clone
  if [ "$TN_SRC/Contents/MacOS/terminal-notifier" -nt "$BIN" ]; then return 0; fi
  return 1
}

build_app() {
  [ -d "$TN_SRC" ] || return 1
  [ -f "$CLAUDE_ICON" ] || return 1
  mkdir -p "$CACHE_DIR"
  rm -rf "$APP"
  cp -R "$TN_SRC" "$APP" || return 1

  # Replace the icon. terminal-notifier's CFBundleIconFile is "Terminal".
  local icon_name
  icon_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$APP/Contents/Info.plist" 2>/dev/null)"
  [ -z "$icon_name" ] && icon_name="Terminal"
  case "$icon_name" in *.icns) : ;; *) icon_name="${icon_name}.icns" ;; esac
  cp -f "$CLAUDE_ICON" "$APP/Contents/Resources/$icon_name" || return 1

  # Unique bundle id so we don't collide with the real Claude.app.
  /usr/bin/plutil -replace CFBundleIdentifier -string "dev.sophie.claude-notifier" "$APP/Contents/Info.plist"
  /usr/bin/plutil -replace CFBundleName       -string "Claude Code"               "$APP/Contents/Info.plist"

  # Re-sign ad-hoc so macOS accepts the modified bundle.
  /usr/bin/codesign --force --deep --sign - "$APP" >/dev/null 2>&1

  printf '%s' "$TN_SRC" > "$STAMP"
}

if needs_rebuild; then
  build_app || true
fi

# Fall back to the system terminal-notifier if the build didn't take.
if [ ! -x "$BIN" ]; then
  BIN="$(command -v terminal-notifier || true)"
fi
[ -x "$BIN" ] || exit 0

# ---------------------------------------------------------------------------
# Skip the notification when the originating kitty tab is already the
# frontmost focused window. No point pinging the user about a tab they're
# looking at; keeps things sane with many concurrent agents.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Click action: raise kitty + focus originating window.
# ---------------------------------------------------------------------------
if [ -n "$WIN_ID" ] && [ -n "$SOCKET" ] && [ -x "$KITTEN" ]; then
  EXECUTE="open -a kitty; '$KITTEN' @ --to '$SOCKET' focus-window --match id:$WIN_ID"
else
  EXECUTE="open -a kitty"
fi

# ---------------------------------------------------------------------------
# Fire and fully detach so the hook returns immediately.
# ---------------------------------------------------------------------------
(
  exec </dev/null >/dev/null 2>&1
  EFFECTIVE_TITLE="$TITLE"
  [ -n "$SUBTITLE" ] && EFFECTIVE_TITLE="$SUBTITLE"
  "$BIN" \
    -title "$EFFECTIVE_TITLE" \
    -message "$MESSAGE" \
    -timeout 30 \
    -execute "$EXECUTE" &
  disown 2>/dev/null || true
) &
disown 2>/dev/null || true

exit 0
