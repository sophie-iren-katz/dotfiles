function claude-unaliased {
    # Make sure the keychain is unlocked when SSH-ing in
    if ! security show-keychain-info >/dev/null 2>&1; then
        security unlock-keychain
    fi

    if [[ -f $HOME/.local/bin/claude ]]; then
        $HOME/.local/bin/claude "$@"
    else
        echo "Claude is not installed"
        return 1
    fi
}

function claude {
    claude-unaliased --dangerously-skip-permissions --chrome --remote-control "$@"
}

function claude-safe {
    claude-unaliased "$@"
}

# function claude-karaconnect {
#     CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude --dangerously-skip-permissions --chrome --remote-control "$@"
# }

# function claude-karaconnect-safe {
#     CLAUDE_CONFIG_DIR=~/.claude-karaconnect _original_claude "$@"
# }

# function claude-kararobot {
#     CLAUDE_CONFIG_DIR=~/.claude-kararobot _original_claude --dangerously-skip-permissions --chrome --remote-control "$@"
# }

# function claude-kararobot-safe {
#     CLAUDE_CONFIG_DIR=~/.claude-kararobot _original_claude "$@"
# }
