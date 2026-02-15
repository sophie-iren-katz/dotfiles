function bitch() {
    if [ $# -eq 0 ]; then
        echo "Usage: bitch <command> [args...] (e.g., bitch test, bitch start, bitch deploy production)"
        return 1
    fi

    # Detect package manager
    if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
        PM="bun"
    elif [ -f "yarn.lock" ]; then
        PM="yarn"
    else
        PM="npm"
    fi

    # Run command with detected package manager
    case "$1" in
        audit|ci|help|install|add|i|link|ln|publish|uninstall|unlink|remove|rm|r|update|un|run|why)
            $PM $@
            ;;
        *)
            $PM run $@
            ;;
    esac
}