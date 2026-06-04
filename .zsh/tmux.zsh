# Attach to a tmux session by name, creating it (detached) if none exists
function tma {
    if [[ -z "${1:-}" ]]; then
        printf "\033[1;31merror:\033[0;0m usage: tma <name>\n"
        return 1
    fi

    local name="${1}"

    if tmux has-session -t "${name}" 2>/dev/null; then
        # Use switch-client when already inside tmux to avoid nesting errors
        if [[ -n "${TMUX:-}" ]]; then
            tmux switch-client -t "${name}"
        else
            tmux attach-session -t "${name}"
        fi
    else
        # Create the session and attach in one step (switch-client if nested)
        if [[ -n "${TMUX:-}" ]]; then
            tmux new-session -d -s "${name}"
            tmux switch-client -t "${name}"
        else
            tmux new-session -A -s "${name}"
        fi
    fi
}

# Kill a tmux session by name
function tmk {
    if [[ -z "${1:-}" ]]; then
        printf "\033[1;31merror:\033[0;0m usage: tmk <name>\n"
        return 1
    fi

    tmux kill-session -t "${1}"
}

# List all tmux sessions
function tmls {
    tmux list-sessions
}
