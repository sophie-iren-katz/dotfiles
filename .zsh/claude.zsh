function _original_claude {
    if [[ -f /Users/sophie/.local/bin/claude ]]; then
        /Users/sophie/.local/bin/claude "$@"
    elif [[ -f /home/sophie/.nvm/versions/node/$(nvm version)/bin/claude ]]; then
        /home/sophie/.nvm/versions/node/$(nvm version)/bin/claude "$@"
    else
        echo "Claude is not installed"
        return 1
    fi
}

# Using sandbox Docker container
# ------------------------------

# function _sandbox_workdir {
#     local container_path="${PWD/#$HOME//home/sophie}"
#     echo "$container_path"
# }

# function claude {
#     if [[ "${SOPHIE_CLAUDE_SANDBOX:-}" == "true" ]]; then
#         echo "Running Claude inside sandbox in god mode..."
#         _original_claude --dangerously-skip-permissions "$@"
#     else
#         /usr/local/bin/docker compose -p claude-sandbox exec -w "$(_sandbox_workdir)" claude-sandbox zsh -c ". ~/.zshrc && claude ${@}"
#     fi
# }

# function claude-karaconnect {
#     if [[ "${SOPHIE_CLAUDE_SANDBOX:-}" == "true" ]]; then
#         echo "Running Claude-karaconnect inside sandbox in god mode..."
#         CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude --dangerously-skip-permissions "$@"
#     else
#         /usr/local/bin/docker compose -p claude-sandbox exec -w "$(_sandbox_workdir)" claude-sandbox zsh -c ". ~/.zshrc && claude-karaconnect ${@}"
#     fi
# }

# function claude-host {
#     if [[ "${SOPHIE_CLAUDE_SANDBOX:-}" == "true" ]]; then
#         echo "Cannot run claude-host inside sandbox"
#         return 1
#     else
#         _original_claude "${@}"
#     fi
# }

# function claude-karaconnect-host {
#     if [[ "${SOPHIE_CLAUDE_SANDBOX:-}" == "true" ]]; then
#         echo "Cannot run claude-karaconnect-host inside sandbox"
#         return 1
#     else
#         CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude "${@}"
#     fi
# }

# Wildly unsafe bare metal
# ------------------------

function claude {
    _original_claude --dangerously-skip-permissions "$@"
}

function claude-safe {
    _original_claude "$@"
}

function claude-karaconnect {
    CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude --dangerously-skip-permissions "$@"
}

function claude-karaconnect-safe {
    CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude "$@"
}

function claude-kararobot {
    CLAUDE_CONFIG_DIR=~/.claude-kararobot _original_claude --dangerously-skip-permissions "$@"
}

function claude-kararobot-safe {
    CLAUDE_CONFIG_DIR=~/.claude-kararobot _original_claude "$@"
}
