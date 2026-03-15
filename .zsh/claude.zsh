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

function _sandbox_workdir {
    local container_path="${PWD/#$HOME//home/sophie}"
    echo "$container_path"
}

function claude {
    if [[ "${SOPHIE_CLAUDE_SANDBOX:-}" == "true" ]]; then
        echo "Running Claude inside sandbox in god mode..."
        _original_claude --dangerously-skip-permissions "$@"
    else
        /usr/local/bin/docker compose -p claude-sandbox exec -w "$(_sandbox_workdir)" claude-sandbox zsh -c ". ~/.zshrc && claude ${@}"
    fi
}

function claude-karaconnect {
    if [[ "${SOPHIE_CLAUDE_SANDBOX:-}" == "true" ]]; then
        CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude --dangerously-skip-permissions "$@"
    else
        /usr/local/bin/docker compose -p claude-sandbox exec -w "$(_sandbox_workdir)" claude-sandbox zsh -c ". ~/.zshrc && claude-karaconnect ${@}"
    fi
}
