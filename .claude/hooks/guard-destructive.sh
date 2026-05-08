#!/usr/bin/env bash
# PreToolUse hook: block rm/mv commands that target paths outside the project.
#
# Receives tool input JSON on stdin with a "command" field.
# Resolves paths and rejects anything outside PROJECT_DIR.
#
# Exit 0 = allow, exit 2 = block (stderr shown to Claude).

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd -P)"

INPUT="$(cat)"

COMMAND="$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)"
[ -z "$COMMAND" ] && exit 0

# Only inspect rm and mv commands
if ! echo "$COMMAND" | grep -qE '(^|\s|;|&&|\|\|)\s*(rm|mv)\s'; then
  exit 0
fi

resolve_path() {
  local raw="$1"

  # Expand tilde
  case "$raw" in
    "~")   raw="$HOME" ;;
    "~/"*) raw="$HOME/${raw#\~/}" ;;
  esac

  # Expand $HOME (string replacement, no eval)
  if [[ "$raw" == *'$HOME'* ]]; then
    raw="${raw/\$HOME/$HOME}"
  fi
  if [[ "$raw" == *'${HOME}'* ]]; then
    raw="${raw/\$\{HOME\}/$HOME}"
  fi

  # Make absolute
  case "$raw" in
    /*) : ;;
    *)
      if [ -d "$raw" ]; then
        raw="$(cd "$raw" && pwd -P)"
      elif [ -d "$(dirname "$raw" 2>/dev/null)" ]; then
        raw="$(cd "$(dirname "$raw")" && pwd -P)/$(basename "$raw")"
      else
        raw="$(pwd -P)/$raw"
      fi
      ;;
  esac

  # Normalize slashes
  echo "$raw" | sed 's|//*|/|g; s|/$||'
}

# Split command into fragments on ; && ||
# Use process substitution to avoid subshell issue with pipes
FRAGMENTS="$(echo "$COMMAND" | sed 's/;/\n/g; s/&&/\n/g; s/||/\n/g')"

while IFS= read -r fragment; do
  # Trim whitespace
  fragment="$(echo "$fragment" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  [ -z "$fragment" ] && continue

  # Check if this fragment contains rm or mv
  if ! echo "$fragment" | grep -qE '(^|\s)(rm|mv)\s'; then
    continue
  fi

  # Split on whitespace and iterate words
  found_cmd=false
  for word in $fragment; do
    if ! $found_cmd; then
      if [[ "$word" == "rm" || "$word" == "mv" ]]; then
        found_cmd=true
      fi
      continue
    fi

    # Skip flags
    case "$word" in
      -*) continue ;;
    esac
    [ -z "$word" ] && continue

    resolved="$(resolve_path "$word")"

    if [[ "$resolved" != "$PROJECT_DIR" && "$resolved" != "$PROJECT_DIR"/* ]]; then
      echo "BLOCKED: '$word' resolves to '$resolved' which is outside '$PROJECT_DIR'" >&2
      exit 2
    fi
  done
done <<< "$FRAGMENTS"

exit 0
