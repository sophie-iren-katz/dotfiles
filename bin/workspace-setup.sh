#!/usr/bin/env bash
# Bring up canonical workspace layout: apps, code projects, kitty windows.
# Idempotent: existing windows are moved, not duplicated. Kitty tabs that
# already exist in any kitty OS window are not re-created.

set -uo pipefail

# ---------------- aerospace helpers ----------------

aero_list() {
  aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}'
}

# aero_find APP [TITLE_SUBSTRING] -> prints first matching window-id (or nothing).
# TITLE_SUBSTRING is a literal substring match against the window title, not a
# regex — `awk -v` strips backslashes from values, which makes regex escapes
# unreliable here.
aero_find() {
  local app="$1" needle="${2:-}"
  aero_list | awk -F'|' -v app="$app" -v needle="$needle" '
    $2==app && (needle=="" || index($3, needle) > 0) { print $1; exit }
  '
}

# aero_wait APP [TITLE_SUBSTRING] -> waits up to ~12s for a matching window-id
aero_wait() {
  local app="$1" needle="${2:-}" wid="" i
  for i in $(seq 1 60); do
    wid=$(aero_find "$app" "$needle")
    [ -n "$wid" ] && { echo "$wid"; return 0; }
    sleep 0.2
  done
  return 1
}

aero_move() {
  local wid="$1" ws="$2"
  if aerospace move-node-to-workspace --window-id "$wid" "$ws" 2>/dev/null; then
    echo "    -> window $wid moved to '$ws'"
  else
    echo "    !! failed to move window $wid to '$ws'" >&2
  fi
}

# ensure_app LABEL APP_NAME WORKSPACE LAUNCH_CMD [TITLE_REGEX]
ensure_app() {
  local label="$1" app="$2" ws="$3" launch="$4" title_re="${5:-}"
  echo "$label..."
  local wid
  wid=$(aero_find "$app" "$title_re")
  if [ -z "$wid" ]; then
    eval "$launch"
    if ! wid=$(aero_wait "$app" "$title_re"); then
      echo "  !! '$app' window never appeared" >&2
      return 1
    fi
  fi
  aero_move "$wid" "$ws"
}

# ---------------- standard apps ----------------
#
# Placement for these apps is handled by on-window-detected rules in
# ~/.aerospace.toml — we just need to ensure each one is running. This is more
# reliable than the title-regex / timeout approach (handles apps opened
# manually too).
#
# Docker Desktop is a background daemon whose dashboard window only appears
# when explicitly opened via the menu bar whale icon. We can't force it open
# from the CLI, so we just activate the engine; the aerospace rule will route
# the window if/when it appears.

for app in Messages Slack Spotify Dashboard Docker; do
  echo "Launching $app (aerospace rule handles placement)..."
  open -ga "$app" 2>/dev/null || echo "  !! failed to launch $app" >&2
done

# Chrome profile windows can't be routed by aerospace rules (same app-id for
# both), so keep the explicit title-substring matching here.
ensure_app "Chrome (Personal)" "Google Chrome" "WebP" \
  'open -na "Google Chrome" --args --profile-directory=Default' \
  '(Personal)'
ensure_app "Chrome (Work)"     "Google Chrome" "WebK" \
  'open -na "Google Chrome" --args --profile-directory="Profile 2"' \
  '(Work)'

# ---------------- VS Code ----------------

# VS Code is idempotent: `code <dir>` focuses an existing window for that
# workspace rather than spawning a new one. We then locate the window by
# basename in its title.
ensure_vscode() {
  local dir="$1" ws="$2"
  local base
  base=$(basename "$dir")
  echo "VS Code: $base..."
  local wid
  wid=$(aero_find "Code" "$base")
  if [ -z "$wid" ]; then
    if command -v code >/dev/null 2>&1; then
      code "$dir" >/dev/null 2>&1 || true
    else
      open -a "Visual Studio Code" "$dir"
    fi
    if ! wid=$(aero_wait "Code" "$base"); then
      echo "  !! VS Code window for '$base' never appeared" >&2
      return 1
    fi
  fi
  aero_move "$wid" "$ws"
}

ensure_vscode "$HOME/Code/karaconnect/ecosystem" "C3"
ensure_vscode "$HOME/Code/dashboard"             "C1"

# ---------------- Kitty ----------------

# kitty's `listen_on unix:/tmp/kitty.sock` actually creates `/tmp/kitty.sock-<PID>`.
# Resolve it dynamically; if no kitty is running yet, bootstrap one (it'll show
# up as a stray empty window — close it manually if you don't want it).
KITTY_SOCK=""
resolve_kitty_sock() {
  local s
  for s in /tmp/kitty.sock-*; do
    [ -S "$s" ] && { echo "unix:$s"; return 0; }
  done
  return 1
}
if ! KITTY_SOCK=$(resolve_kitty_sock); then
  echo "Kitty not running, bootstrapping..."
  open -na kitty
  for _i in $(seq 1 50); do
    sleep 0.2
    KITTY_SOCK=$(resolve_kitty_sock) && break
  done
fi
if [ -z "$KITTY_SOCK" ]; then
  echo "  !! couldn't find kitty socket at /tmp/kitty.sock-*, skipping kitty setup" >&2
  exit 1
fi

kty() { kitty @ --to "$KITTY_SOCK" "$@"; }

kty_state() { kty ls 2>/dev/null || echo "[]"; }

# kty_find_tab TITLE -> prints "<kitty_window_id> <platform_window_id>" if a
# tab with this exact title exists anywhere, else empty.
#
# We match on the title set via `--tab-title` because it's a stable identity:
# kitty preserves the override even when the user cd's around or the foreground
# process changes. cwd/process matching is fragile — a shell tab that was "the
# AI3 ecosystem shell" can drift to any cwd, then either fail to match (and
# get duplicated) or get mis-claimed by another spec with that cwd (causing
# windows to swap workspaces).
kty_find_tab() {
  local title="$1"
  [ -z "$title" ] && return 0
  kty_state | jq -r --arg title "$title" '
    [
      .[] as $osw | $osw.tabs[] as $tab | $tab.windows[] as $w |
      select($tab.title == $title) |
      "\($w.id) \($osw.platform_window_id)"
    ] | .[0] // ""
  '
}

# kty_spawn_oswin CWD CMD TITLE -> prints "<new_window_id> <platform_window_id>"
# When CMD is non-empty we wrap with `zsh -l -i -c '<cmd>'` so .zprofile and
# .zshrc are sourced (Homebrew PATH, aliases, etc.) before the command runs.
# --hold keeps the OS window open after the command exits — both as a safety
# net if the wrapper can't start, and so output stays visible.
# TITLE, if non-empty, becomes the tab label (so it stays meaningful instead
# of falling back to "zsh" once the wrapper's shell takes over).
kty_spawn_oswin() {
  local cwd="$1" cmd="$2" title="${3:-}" new_id="" plat=""
  local title_args=()
  [ -n "$title" ] && title_args=(--tab-title "$title")
  if [ -z "$cmd" ]; then
    new_id=$(kty launch --type=os-window --cwd="$cwd" \
      ${title_args[@]+"${title_args[@]}"})
  else
    new_id=$(kty launch --type=os-window --hold --cwd="$cwd" \
      ${title_args[@]+"${title_args[@]}"} \
      zsh -l -i -c "$cmd")
  fi
  # Wait for kitty to register the new OS window
  local i
  for i in $(seq 1 30); do
    plat=$(kty_state | jq -r --argjson wid "$new_id" '
      .[] | select(any(.tabs[].windows[]; .id == $wid)) | .platform_window_id
    ' | head -1)
    [ -n "$plat" ] && break
    sleep 0.1
  done
  echo "$new_id $plat"
}

# kty_add_tab TARGET_WINDOW_ID CWD CMD TITLE
kty_add_tab() {
  local target_id="$1" cwd="$2" cmd="$3" title="${4:-}"
  local title_args=()
  [ -n "$title" ] && title_args=(--tab-title "$title")
  if [ -z "$cmd" ]; then
    kty launch --type=tab --match "id:$target_id" --cwd="$cwd" \
      ${title_args[@]+"${title_args[@]}"} >/dev/null
  else
    kty launch --type=tab --hold --match "id:$target_id" --cwd="$cwd" \
      ${title_args[@]+"${title_args[@]}"} \
      zsh -l -i -c "$cmd" >/dev/null
  fi
}

# provision_kitty_window WORKSPACE CWD1\|CMD1\|TITLE1 [CWD2\|CMD2\|TITLE2 ...]
# - If first tab already exists somewhere, that OS window is reused.
# - Otherwise a fresh OS window is spawned with the first tab.
# - Subsequent tabs are added only if they don't already exist anywhere.
# - The OS window is then moved to WORKSPACE.
# Each pair: cwd|cmd|title; cmd and title are optional (empty = none).
parse_pair() {
  # $1 = pair string; sets vars __cwd __cmd __title in the caller's scope.
  IFS='|' read -r __cwd __cmd __title <<<"$1"
  __cwd="${__cwd/#\~/$HOME}"
  __title="${__title:-}"
}

provision_kitty_window() {
  local ws="$1"; shift
  echo "Kitty: window for '$ws'..."

  local target_win_id="" target_plat="" __cwd __cmd __title
  parse_pair "$1"; shift
  local first_cwd="$__cwd" first_cmd="$__cmd" first_title="$__title"

  local found
  found=$(kty_find_tab "$first_title")
  if [ -n "$found" ]; then
    target_win_id="${found% *}"
    target_plat="${found##* }"
    echo "  reusing existing OS window (platform_id=$target_plat) via tab '$first_title'"
  else
    echo "  spawning new OS window with tab '$first_title'  (\$ ${first_cmd:-<shell>})"
    local spawn
    spawn=$(kty_spawn_oswin "$first_cwd" "$first_cmd" "$first_title")
    target_win_id="${spawn% *}"
    target_plat="${spawn##* }"
  fi

  local pair
  for pair in "$@"; do
    parse_pair "$pair"
    found=$(kty_find_tab "$__title")
    if [ -n "$found" ]; then
      echo "  tab '$__title' already open elsewhere, skipping"
    else
      echo "  adding tab '$__title'  (\$ ${__cmd:-<shell>})"
      kty_add_tab "$target_win_id" "$__cwd" "$__cmd" "$__title"
    fi
  done

  if [ -n "$target_plat" ]; then
    aero_move "$target_plat" "$ws"
  else
    echo "  !! couldn't determine OS window platform id" >&2
  fi
}

provision_kitty_window "Term" \
  "$HOME|bash $HOME/.dotfiles/bin/watch-deploys.sh|watch-deploys" \
  "$HOME|dashboard-daemon|dashboard-daemon" \
  "$HOME/Code/dashboard|just dev|dashboard: dev" \
  "$HOME/Code/dashboard|just daemon|dashboard: daemon"

echo "Done."
