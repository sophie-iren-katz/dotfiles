#!/usr/bin/env bash
# PreToolUse hook: block Write/Edit/MultiEdit on sensitive paths in the user's
# home directory, even under bypassPermissions mode.
#
# Receives tool input JSON on stdin with a "file_path" field.
# Exit 0 = allow, exit 2 = block (stderr shown to Claude).

set -uo pipefail

INPUT="$(cat)"

FILE_PATH="$(echo "$INPUT" | jq -r '.file_path // .tool_input.file_path // empty' 2>/dev/null)"
[ -z "$FILE_PATH" ] && exit 0

# Expand ~ and $HOME, then make absolute
case "$FILE_PATH" in
  "~")   FILE_PATH="$HOME" ;;
  "~/"*) FILE_PATH="$HOME/${FILE_PATH#\~/}" ;;
esac
if [[ "$FILE_PATH" == *'$HOME'* ]]; then
  FILE_PATH="${FILE_PATH/\$HOME/$HOME}"
fi
case "$FILE_PATH" in
  /*) : ;;
  *)  FILE_PATH="$(pwd -P)/$FILE_PATH" ;;
esac
# Collapse double slashes
FILE_PATH="$(echo "$FILE_PATH" | sed 's|//*|/|g; s|/$||')"

# Only enforce for paths under $HOME
case "$FILE_PATH" in
  "$HOME"/*) : ;;
  *) exit 0 ;;
esac

# Always allow ~/.claude (auto-memory etc.)
case "$FILE_PATH" in
  "$HOME"/.claude|"$HOME"/.claude/*) exit 0 ;;
esac

# Protected directories (block any path under them)
PROTECTED_DIRS=(
  ".aws" ".biome" ".bun" ".cocoapods" ".config" ".docker" ".expo"
  ".gnupg" ".keys" ".kube" ".local" ".maestro" ".npm" ".nvm"
  ".oh-my-zsh" ".pulumi" ".ssh" ".Trash" ".vim" ".vscode" ".yarn" ".zsh"
)

for dir in "${PROTECTED_DIRS[@]}"; do
  if [[ "$FILE_PATH" == "$HOME/$dir" || "$FILE_PATH" == "$HOME/$dir"/* ]]; then
    echo "BLOCKED: '$FILE_PATH' is under protected directory ~/$dir" >&2
    exit 2
  fi
done

# Protected wildcard directories (.pulumi-*)
case "$FILE_PATH" in
  "$HOME"/.pulumi-*/*|"$HOME"/.pulumi-*)
    echo "BLOCKED: '$FILE_PATH' is under protected directory ~/.pulumi-*" >&2
    exit 2
    ;;
esac

# Protected top-level files (exact match)
PROTECTED_FILES=(
  ".bash_profile" ".bashrc" ".bunfig.toml" ".gitconfig" ".netrc"
  ".npmrc" ".profile" ".zprofile" ".zshrc"
)

for file in "${PROTECTED_FILES[@]}"; do
  if [[ "$FILE_PATH" == "$HOME/$file" ]]; then
    echo "BLOCKED: '$FILE_PATH' is a protected dotfile (~/$file)" >&2
    exit 2
  fi
done

exit 0
