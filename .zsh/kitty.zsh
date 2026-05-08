function ktabcol {
    local active_bg=""
    local inactive_bg=""

    # These values come from kitty.conf (color0, color1, etc.)
    #
    # For the inactive colors I just set the L of HSL to 20%

    case "${1:-}" in
        "red")
            active_bg="#ff355b"
            inactive_bg="#660013"
            ;;
        "green")
            active_bg="#b6e875"
            inactive_bg="#38570f"
            ;;
        "yellow")
            active_bg="#ffc150"
            inactive_bg="#664200"
            ;;
        "blue")
            active_bg="#75d3ff"
            inactive_bg="#004666"
            ;;
        "magenta")
            active_bg="#b975e6"
            inactive_bg="#3a1056"
            ;;
        "cyan")
            active_bg="#6cbeb5"
            inactive_bg="#1f4742"
            ;;
        *)
            echo "error: unknown color: ${1:-}"
            return 1
            ;;
    esac

    kitten @ set-tab-color --match recent:0 "active_bg=${active_bg}" "inactive_bg=${inactive_bg}"
}
