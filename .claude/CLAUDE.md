# Guard hooks

If a guard hook in `~/.claude/hooks/` blocks an action, surface the block and stop. Don't switch tools to route around it, don't weaken the guard or settings, and don't toggle bypass env vars on your own.

# Before writing new functionality

- Research third-party dependencies that can be used instead of writing custom solutions
- Prefer modeling new features after existing patterns in the codebase rather than introducing new machinery

# Logs

- When asked to print logs or output, print the raw content first; summarize only if asked

# Verification Before Claiming Done

- Never assume database/schema shapes — verify with a query, grep, or by reading the schema file before making edits or claims
- When fixing a bug, reproduce or trace it end-to-end before proposing a fix; do not guess at column/field names
- After schema/timestamp changes, check whether a data migration is also required for existing records
- Check AWS assumptions against AWS itself with the `aws` CLI rather than trusting the IaC source — the deployed state may have drifted, or a recent change may not be deployed yet. Use **read-only** commands only (`aws iam get-role-policy`, `aws lambda get-function-configuration`, `aws iam simulate-principal-policy`, `aws logs tail`, `aws ssm get-parameter`, etc.). Never run any AWS command that mutates state (`put-*`, `create-*`, `update-*`, `delete-*`, `attach-*`, `detach-*`) — surface what needs to change and let the user apply it through IaC.

# Environment & Tooling Constraints

- Target macOS bash 3.2 for shell scripts (no `declare -A`, no bash 4+ features); ensure signal handlers propagate to child processes
- Be aware that justfile `dotenv-load` can override Bun's `--env-file` behavior
