function gsub {
    # Arguments
    local mode=""
    local skip_root="false"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                if [[ -n "${mode}" ]]; then
                    printf "\033[1;31merror:\033[0;0m can only use one of --all, --dirty, or --clean at a time\n"
                    return 1
                fi

                mode="all"
                ;;
            --dirty)
                if [[ -n "${mode}" ]]; then
                    printf "\033[1;31merror:\033[0;0m can only use one of --all, --dirty, or --clean at a time\n"
                    return 1
                fi

                mode="dirty"
                ;;
            --clean)
                if [[ -n "${mode}" ]]; then
                    printf "\033[1;31merror:\033[0;0m can only use one of --all, --dirty, or --clean at a time\n"
                    return 1
                fi

                mode="clean"
                ;;
            --skip-root)
                skip_root="true"
                ;;
            -h|--help)
                echo "Usage: gsub [OPTIONS]"
                echo
                echo "OPTIONS:"
                echo "  --all        Show all submodules color coded by status (default)"
                echo "  --dirty      Show only dirty submodules"
                echo "  --clean      Show only clean submodules"
                echo "  --skip-root  Do not show the root repository as a submodule"
                echo "  -h, --help   Show this help message and exit"
                return 1
                ;;
            *)
                printf "\033[1;31merror:\033[0;0m unknown argument ${1}\n"
                return 1
                ;;
        esac
        shift
    done

    if [[ -z "${mode}" ]]; then
        mode="all"
    fi

    # List submodules
    results="$(
        git submodule foreach --quiet '
            changes=$(git status --porcelain)
            if [[ -n "${changes}" ]]; then
                echo "$path *"
            else
                echo "$path"
            fi
        '
    )"

    # Unless the root is skipped, add it as well
    if [[ "${skip_root}" == "false" ]]; then
        local root_dir="$(git rev-parse --show-toplevel)"
        local root_changes="$(git status --porcelain)"
        local repository_name="$(basename "${root_dir}")"

        if [[ -n "${root_changes}" ]]; then
            if [[ -n "${results}" ]]; then
                results="${results}\n${repository_name} *"
            else
                results="${repository_name} *"
            fi
        else
            if [[ -n "${results}" ]]; then
                results="${results}\n${repository_name}"
            else
                results="${repository_name}"
            fi
        fi
    fi

    # Filter results based on mode
    case "${mode}" in
        "all")
            echo "${results}" | while read -r line; do
                if [[ "${line}" != *" *" ]]; then
                    echo "\033[2;32m${line}\033[0;0m"
                fi
            done
            echo "${results}" | while read -r line; do
                if [[ "${line}" == *" *" ]]; then
                    echo "\033[1;33m${line}\033[0;0m"
                fi
            done
            ;;
        "dirty")
            echo "${results}" | grep -E " \\*\$" | sed -E "s/ \\*\$//"
            ;;
        "clean")
            echo "${results}" | grep -vE " \\*\$"
            ;;
        *)
            printf "\033[1;31merror:\033[0;0m unknown mode ${mode}\n"
            return 1
            ;;
    esac
}

function gsta {
    # Arguments
    local filter=""
    local mode=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                if [[ -n "${mode}" ]]; then
                    printf "\033[1;31merror:\033[0;0m can only use one of --all, --only-added, or --only-unadded at a time\n"
                    return 1
                fi

                mode="all"
                ;;
            --only-added)
                if [[ -n "${mode}" ]]; then
                    printf "\033[1;31merror:\033[0;0m can only use one of --all, --only-added, or --only-unadded at a time\n"
                    return 1
                fi

                mode="only-added"
                ;;
            --only-unadded)
                if [[ -n "${mode}" ]]; then
                    printf "\033[1;31merror:\033[0;0m can only use one of --all, --only-added, or --only-unadded at a time\n"
                    return 1
                fi

                mode="only-unadded"
                ;;
            -h|--help)
                echo "Usage: gsta [OPTIONS] [FILTER]"
                echo
                echo "FILTER is an optional regex pattern with which to filter the changes."
                echo
                echo "OPTIONS:"
                echo "  -h, --help   Show this help message and exit"
                return 1
                ;;
            *)
                if [[ -z "${filter}" ]]; then
                    filter="${1}"
                else
                    printf "\033[1;31merror:\033[0;0m can only use one filter\n"
                    return 1
                fi
                ;;
        esac
        shift
    done

    if [[ -z "${mode}" ]]; then
        mode="all"
    fi
    
    # Gather changes
    local root_dir="$(git rev-parse --show-toplevel)"
    local changes
    
    if [[ -n "${filter}" ]]; then
        changes=$(git status --porcelain --untracked-files=all | grep -E "${filter}")
    else
        changes=$(git status --porcelain --untracked-files=all)
    fi

    local changes_formatted="$(echo "${changes}" | sed -E "
        s/^ M /  \x1b[0;33mModified:          \x1b[0m/; t
        s/^M /  \x1b[0;33mModified (added): \x1b[0m/; t
        s/^ D /  \x1b[0;31mDeleted:           \x1b[0m/; t
        s/^D /  \x1b[0;31mDeleted (added):  \x1b[0m/; t
        s/^\?\? /  \x1b[0;36mNew:               \x1b[0m/; t
        s/^UU /  \x1b[0;31mNew (added): \x1b[0m/; t
        s/^R /  \x1b[0;35mRenamed:          \x1b[0m/; t
        s/^A /  \x1b[0;32mNew (added):      \x1b[0m/; t
        s/^ /  /
    ")"

    case "${mode}" in
        all)
            echo "${changes_formatted}"
            ;;
        only-added)
            echo "${changes_formatted}" | grep -E '\(added\)' | sed -E 's/.*\(added\):.*0m//'
            ;;
        only-unadded)
            echo "${changes_formatted}" | grep -vE '\(added\)' | sed -E 's/.*:.*0m//' | sed -E 's/.*-> *//'
            ;;
        *)
            printf "\033[1;31merror:\033[0;0m unknown mode ${mode}\n"
            return 1
            ;;
    esac
}

# Stage one or all changes in current repository
function gadd {
    if [[ -z "${1:-}" ]]; then
        git add --all .
    else
        git add --all "${@}"
    fi

    gsta
}

# Unstage one or all changes in current repository
function gunadd {
    if [[ -z "${1:-}" ]]; then
        git restore --staged .
    else
        git restore --staged "${@}"
    fi

    gsta
}

# Stage and commit all changes in current repository
function gcom {
    if [[ -z "$(gsta --only-unadded)" ]]; then
        git add --all .
    fi

    gsta
    echo
    git commit -m "$*"
}

# Undo last commit in current repository
function guncom {
    local last_message="$(git log -1 --pretty=%B)"

    git reset HEAD~1
    echo
    gsta
    echo
    echo "${last_message}"
}

# Reset all changes in current repository
function greset {
    git reset --hard HEAD
    echo
    git pull
    echo
    gsta
}

# Stage, commit, and push all changes in current repository
function gsend {
    gcom "$*"
    echo
    git push -u origin HEAD
}

# Diff changes in current repository using Cursor
function gdiff {
    # Find relevant files
    local files=()
    for pattern in "$@"; do
        files+=($(git ls-files --cached --others --exclude-standard | grep -E "$pattern"))
    done

    # Show warning if in subdirectory
    if [[ "$(git rev-parse --show-toplevel)" != "$(pwd)" ]]; then
        printf "\033[1;33mwarning:\033[0;0m only showing diff for files in the current directory, not the entire repository.\n"

        if [[ ${#files[@]} -gt 0 ]]; then
            echo
        fi
    fi

    if [[ ${#files[@]} -gt 0 ]]; then
        echo "Showing diff for files:"
        for file in "${files[@]}"; do
            echo "  $file"
        done
    fi

    git difftool --no-prompt -- "${files[@]}"
}
