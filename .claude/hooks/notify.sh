#!/usr/bin/env bash
# Click-to-focus notification for Claude Code hooks.
#
# Usage: notify.sh <fallback_title> <message> [override_label]
#
# The notification title is derived from the kitty tab containing the
# originating window ($KITTY_WINDOW_ID). If we can't reach kitty, falls
# back to override_label, then fallback_title.
#
# Self-bootstraps a clone of terminal-notifier.app with Claude.app's icon
# (terminal-notifier's -sender bundle-ID spoofing is broken on macOS
# Sonoma+; this is the reliable workaround).
#
# Skips the notification when the originating kitty tab is already the
# frontmost focused window.
#
# On click, raises kitty.app and focuses the originating kitty window via
# $KITTY_WINDOW_ID and the kitty remote-control unix socket.

set -uo pipefail

FALLBACK_TITLE="${1:-Claude Code}"
MESSAGE="${2:-}"
OVERRIDE_LABEL="${3:-}"

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
  if [ "$TN_SRC/Contents/MacOS/terminal-notifier" -nt "$BIN" ]; then return 0; fi
  return 1
}

build_app() {
  [ -d "$TN_SRC" ] || return 1
  [ -f "$CLAUDE_ICON" ] || return 1
  mkdir -p "$CACHE_DIR"
  rm -rf "$APP"
  cp -R "$TN_SRC" "$APP" || return 1

  local icon_name
  icon_name="$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$APP/Contents/Info.plist" 2>/dev/null)"
  [ -z "$icon_name" ] && icon_name="Terminal"
  case "$icon_name" in *.icns) : ;; *) icon_name="${icon_name}.icns" ;; esac
  cp -f "$CLAUDE_ICON" "$APP/Contents/Resources/$icon_name" || return 1

  /usr/bin/plutil -replace CFBundleIdentifier -string "dev.sophie.claude-notifier" "$APP/Contents/Info.plist"
  /usr/bin/plutil -replace CFBundleName       -string "Claude Code"               "$APP/Contents/Info.plist"

  /usr/bin/codesign --force --deep --sign - "$APP" >/dev/null 2>&1

  printf '%s' "$TN_SRC" > "$STAMP"
}

if needs_rebuild; then
  build_app || true
fi

if [ ! -x "$BIN" ]; then
  BIN="$(command -v terminal-notifier || true)"
fi
[ -x "$BIN" ] || exit 0

# ---------------------------------------------------------------------------
# Query kitty once: derive focus state AND the originating tab's title.
# ---------------------------------------------------------------------------
KITTEN=/Applications/kitty.app/Contents/MacOS/kitten
SOCKET="${KITTY_LISTEN_ON:-}"
WIN_ID="${KITTY_WINDOW_ID:-}"
TAB_TITLE=""

if [ -n "$WIN_ID" ] && [ -n "$SOCKET" ] && [ -x "$KITTEN" ]; then
  KITTY_LS="$("$KITTEN" @ --to "$SOCKET" ls 2>/dev/null || true)"
  if [ -n "$KITTY_LS" ]; then
    # Skip if our tab is the frontmost focused one.
    FRONT_APP="$(/usr/bin/osascript -e 'tell application "System Events" to name of first application process whose frontmost is true' 2>/dev/null)"
    if [ "$FRONT_APP" = "kitty" ]; then
      FOCUSED_ID="$(printf '%s' "$KITTY_LS" \
        | /usr/bin/jq -r '.[] | select(.is_focused) | .tabs[] | select(.is_focused) | .windows[] | select(.is_focused) | .id' \
        | head -1)"
      if [ "$FOCUSED_ID" = "$WIN_ID" ]; then
        exit 0
      fi
    fi

    # Find the title of the tab containing our window.
    TAB_TITLE="$(printf '%s' "$KITTY_LS" \
      | /usr/bin/jq -r --argjson wid "$WIN_ID" \
          '.[] | .tabs[] | select(any(.windows[]; .id == $wid)) | .title' \
      | head -1)"
  fi
fi

# Pick the title: kitty tab title > override > fallback.
if [ -n "$TAB_TITLE" ]; then
  TITLE="$TAB_TITLE"
elif [ -n "$OVERRIDE_LABEL" ]; then
  TITLE="$OVERRIDE_LABEL"
else
  TITLE="$FALLBACK_TITLE"
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
  GROUP_ARGS=()
  if [ -n "$WIN_ID" ]; then
    GROUP_ARGS=(-group "kitty-window-$WIN_ID")
  fi
  "$BIN" \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -timeout 30 \
    -execute "$EXECUTE" \
    "${GROUP_ARGS[@]}" &
  disown 2>/dev/null || true
) &
disown 2>/dev/null || true

exit 0
