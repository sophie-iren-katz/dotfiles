#!/usr/bin/env bash
# PreToolUse hook: block AWS write commands unless the resolved profile uses
# ReadOnlyAccess. Covers:
#   - aws (any subcommand; the AWS CLI itself enforces no writes under
#     ReadOnlyAccess, but blocking early gives faster, clearer feedback)
#   - pulumi up/destroy/refresh/import/cancel/state delete/state rename/
#     state unprotect/stack rm/stack init/stack export/stack import
#   - cdk deploy/destroy/import/rollback/bootstrap/migrate
#
# Read-only subcommands (pulumi preview, cdk synth/diff/ls, etc.) are
# allowed regardless of role.
#
# Override: set CLAUDE_AWS_WRITE=1 to bypass.
#
# Exit 0 = allow, exit 2 = block.

set -uo pipefail

if [ "${CLAUDE_AWS_WRITE:-}" = "1" ]; then
  exit 0
fi

INPUT="$(cat)"
COMMAND="$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)"
[ -z "$COMMAND" ] && exit 0

# ---------------------------------------------------------------------------
# Decide whether the command needs role-checking, and which "tool" matched.
# ---------------------------------------------------------------------------
TOOL=""
if echo "$COMMAND" | grep -qE '(^|[[:space:];&|])aws[[:space:]]'; then
  TOOL=aws
elif echo "$COMMAND" | grep -qE '(^|[[:space:];&|])pulumi[[:space:]]+(up|destroy|refresh|import|cancel)([[:space:]]|$)'; then
  TOOL=pulumi
elif echo "$COMMAND" | grep -qE '(^|[[:space:];&|])pulumi[[:space:]]+state[[:space:]]+(delete|rename|unprotect)([[:space:]]|$)'; then
  TOOL=pulumi
elif echo "$COMMAND" | grep -qE '(^|[[:space:];&|])pulumi[[:space:]]+stack[[:space:]]+(rm|init|export|import)([[:space:]]|$)'; then
  TOOL=pulumi
elif echo "$COMMAND" | grep -qE '(^|[[:space:];&|])cdk[[:space:]]+(deploy|destroy|import|rollback|bootstrap|migrate)([[:space:]]|$)'; then
  TOOL=cdk
else
  exit 0
fi

AWS_CONFIG="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

# ---------------------------------------------------------------------------
# Resolve the AWS profile used by this command.
# ---------------------------------------------------------------------------
PROFILE=""
if echo "$COMMAND" | grep -qE -- '--profile\s+\S+'; then
  PROFILE="$(echo "$COMMAND" | grep -oE -- '--profile\s+\S+' | head -1 | awk '{print $2}')"
elif echo "$COMMAND" | grep -qE -- '--profile=\S+'; then
  PROFILE="$(echo "$COMMAND" | grep -oE -- '--profile=\S+' | head -1 | sed 's/--profile=//')"
fi

if [ -z "$PROFILE" ]; then
  PROFILE="${AWS_PROFILE:-default}"
fi

# ---------------------------------------------------------------------------
# Look up the SSO role for that profile.
# ---------------------------------------------------------------------------
if [ "$PROFILE" = "default" ]; then
  SECTION_PATTERN="^\[default\]"
else
  SECTION_PATTERN="^\[profile ${PROFILE}\]"
fi

SECTION_BODY="$(sed -n "/$SECTION_PATTERN/,/^\[/p" "$AWS_CONFIG" 2>/dev/null | sed '1d;$d')"
ROLE_NAME="$(echo "$SECTION_BODY" | grep -E '^[[:space:]]*sso_role_name[[:space:]]*=' | grep -v '^[[:space:]]*;' | tail -1 | sed 's/.*=[[:space:]]*//' | sed 's/[[:space:]]*$//')"

# Non-SSO profile (no sso_role_name) — out of scope for this guard.
if [ -z "$ROLE_NAME" ]; then
  exit 0
fi

if [ "$ROLE_NAME" = "ReadOnlyAccess" ]; then
  exit 0
fi

echo "BLOCKED: $TOOL command on AWS profile '$PROFILE' uses role '$ROLE_NAME' (not ReadOnlyAccess)." >&2
echo "Claude is restricted to read-only AWS access. Run the command directly, or set CLAUDE_AWS_WRITE=1 to bypass." >&2
exit 2
