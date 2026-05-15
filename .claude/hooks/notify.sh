#!/usr/bin/env bash
# Click-to-focus notification for Claude Code hooks.
#
# Usage: notify.sh <fallback_title> <message> [override_label]
#
# The notification title is derived from the kitty tab containing the
# originating window ($KITTY_WINDOW_ID). If we can't reach kitty, falls
# back to override_label, then fallback_title.
#
# Requires the v3.x fork of terminal-notifier from
# https://github.com/sophie-iren-katz/terminal-notifier, which supports
# -sender bundle-ID spoofing natively via self-cloning bundles.
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
# Require the v3.x fork on PATH.
# ---------------------------------------------------------------------------
BIN="$(command -v terminal-notifier || true)"
if [ -z "$BIN" ]; then
  cat >&2 <<'EOF'
notify.sh: terminal-notifier not found on PATH.

This script requires the v3.x fork from sophie-iren-katz/terminal-notifier.
To install:

  git clone https://github.com/sophie-iren-katz/terminal-notifier.git
  cd terminal-notifier
  just install
EOF
  exit 1
fi

TN_MAJOR="$("$BIN" -version 2>/dev/null | sed -nE 's/.* ([0-9]+)\.[0-9]+\.[0-9]+.*/\1/p')"
if [ "$TN_MAJOR" != "3" ]; then
  if [ "$TN_MAJOR" = "2" ]; then
    cat >&2 <<EOF
notify.sh: found terminal-notifier v2.x at $BIN — this script requires v3.x.

Uninstall the existing version first (e.g. \`brew uninstall terminal-notifier\`)
and remove $BIN if it still exists. Then install the fork:

  git clone https://github.com/sophie-iren-katz/terminal-notifier.git
  cd terminal-notifier
  just install
EOF
  else
    cat >&2 <<EOF
notify.sh: terminal-notifier at $BIN is not v3.x.

This script requires the v3.x fork from sophie-iren-katz/terminal-notifier:

  git clone https://github.com/sophie-iren-katz/terminal-notifier.git
  cd terminal-notifier
  just install
EOF
  fi
  exit 1
fi

SENDER_BUNDLE_ID="com.anthropic.claudefordesktop"

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
    -sender "$SENDER_BUNDLE_ID" \
    -title "$TITLE" \
    -message "$MESSAGE" \
    -timeout 30 \
    -execute "$EXECUTE" \
    "${GROUP_ARGS[@]}" &
  disown 2>/dev/null || true
) &
disown 2>/dev/null || true

exit 0
