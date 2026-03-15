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
            changes=$(git status --porcelain --untracked-files=all --ignore-submodules=all)
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
        local root_changes="$(git status --porcelain --untracked-files=all --ignore-submodules=all)"
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

function gsubsta {
    for submodule in $(gsub --dirty --skip-root); do
        printf "\033[1;33m${submodule}:\033[0;0m\n"
        (cd "${submodule}" && gsta)
        printf "\n"
    done

    local root_dir="$(git rev-parse --show-toplevel)"
    local root_changes="$(git status --porcelain --untracked-files=all --ignore-submodules=all)"

    if [[ -n "${root_changes}" ]]; then
        local repository_name="$(basename "${root_dir}")"
        printf "\033[1;33m${repository_name}:\033[0;0m\n"
        (cd "${root_dir}" && gsta)
        printf "\n"
    fi
}

function gsubbr {
    for submodule in $(git submodule foreach --quiet 'echo $path'); do
        local branch="$(cd "${submodule}" && git branch --show-current)"
        if [[ "${branch}" != "develop" ]] && [[ "${branch}" != "v1" ]]; then
            printf "\033[1;32m${submodule}:\033[0;0m ${branch}\n"
        fi
    done

    local root_dir="$(git rev-parse --show-toplevel)"
    local root_changes="$(git status --porcelain --untracked-files=all --ignore-submodules=all)"

    if [[ -n "${root_changes}" ]]; then
        local repository_name="$(basename "${root_dir}")"
        printf "\033[1;33m${repository_name}:\033[0;0m $(cd "${root_dir}" && git branch --show-current)\n"
    fi
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
        changes=$(git status --porcelain --untracked-files=all --ignore-submodules=all | grep -E "${filter}")
    else
        changes=$(git status --porcelain --untracked-files=all --ignore-submodules=all)
    fi

    if [[ -z "${changes}" ]]; then
        return 0
    fi

    local changes_formatted="$(echo "${changes}" | sed -E "
        s/^ M /  \x1b[0;33mModified:          \x1b[0m/; t
        s/^M /  \x1b[0;33mModified (added): \x1b[0m/; t
        s/^ D /  \x1b[0;31mDeleted:           \x1b[0m/; t
        s/^D /  \x1b[0;31mDeleted (added):  \x1b[0m/; t
        s/^\?\? /  \x1b[0;36mNew:               \x1b[0m/; t
        s/^UU /  \x1b[0;31mNew (added):       \x1b[0m/; t
        s/^R /  \x1b[0;35mRenamed:          \x1b[0m/; t
        s/^A /  \x1b[0;32mNew (added):      \x1b[0m/; t
        s/^AA/  \x1b[0;32mMerge needed:     \x1b[0m/; t
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
    if [[ -z "$(gsta --only-added)" ]]; then
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
    git clean -fd
    echo
    git pull
    echo
    gsta
}

# Push changes to a remote branch
function gpush {
    git push --set-upstream origin $(git branch --show-current)
}

# Stage, commit, and push all changes in current repository
function gsend {
    gcom "$*"
    echo
    gpush
}

# Diff changes in current repository using Cursor
function gdiff {
    local pattern="${1:-}"
    local root_dir="$(git rev-parse --show-toplevel)"

    # Find relevant files
    local files=()
    if [[ -n "${pattern}" ]]; then
        files+=($(cd "${root_dir}" && git status --porcelain --untracked-files=all --ignore-submodules=all | sed -E 's/^[ MAD?]* +//' | grep -E "${pattern}"))

        if [[ ${#files[@]} -eq 0 ]]; then
            printf "\033[1;31merror:\033[0;0m no files found matching pattern ${pattern}\n"
            return 1
        fi
    else
        files+=($(cd "${root_dir}" && git status --porcelain --untracked-files=all --ignore-submodules=all | sed -E 's/^[ MAD?]* +//'))
    fi

    if [[ ${#files[@]} -gt 0 ]]; then
        echo "Showing diff for files:"
        for file in "${files[@]}"; do
            echo "  $file"
        done

        (cd "${root_dir}" && git difftool --no-prompt -- "${files[@]}")
    else
        (cd "${root_dir}" && git difftool --no-prompt)
    fi
}

function ghlog {
    local last_run
    local last_run_id
    local last_run_display_title
    local last_run_status
    local last_run_status_colored
    local last_run_workflow_name
    local last_run_conclusion
    local last_run_url

    last_run="$(gh run list --json workflowName,status,databaseId,displayTitle,conclusion,url | jq '[.[] | select((.workflowName | ascii_downcase | (contains("publish") or contains("deploy"))))] | if length > 0 then .[0] else null end')"
    last_run_id="$(echo "${last_run}" | jq -r '.databaseId')"
    last_run_display_title="$(echo "${last_run}" | jq -r '.displayTitle')"
    last_run_status="$(echo "${last_run}" | jq -r '.status')"
    last_run_workflow_name="$(echo "${last_run}" | jq -r '.workflowName')"
    last_run_conclusion="$(echo "${last_run}" | jq -r '.conclusion')"
    last_run_url="$(echo "${last_run}" | jq -r '.url')"

    if [[ "${last_run_conclusion}" == "failure" ]]; then
        last_run_status_colored="\033[0;31mcompleted with failure\033[0;0m"
    else
        case "${last_run_status}" in
            completed|success)
                last_run_status_colored="\033[0;32m${last_run_status}\033[0;0m"
                ;;
            action_required|failure|stale|startup_failure|cancelled|timed_out)
                last_run_status_colored="\033[0;31m${last_run_status}\033[0;0m"
                ;;
            *)
                last_run_status_colored="\033[0;33m${last_run_status}\033[0;0m"
                ;;
        esac
    fi

    echo -e "\033[0;36m${last_run_workflow_name}:\033[0;0m \033[1m${last_run_display_title}\033[0;0m \033[0;90m-\033[0;0m ${last_run_status_colored} \033[0;90m(${last_run_url})\033[0;0m"

    if [[ "${last_run_status}" == "queued" ]]; then
        echo -e "Run is still queued, trying again in 5 seconds..."
        sleep 5
        ghlog
        return $?
    fi

    if [[ "${last_run_conclusion}" == "failure" ]]; then
        gh run view "${last_run_id}" --log-failed | less -R
    else
        case "${last_run_status}" in
            in_progress)
                gh run watch "${last_run_id}"
                ;;
            failure|startup_failure)
                gh run view "${last_run_id}" --log-failed | less -R
                ;;
            *)
                gh run view "${last_run_id}" | less -R
                ;;
        esac
    fi
}

function gh {
    local original_gh

    if [[ -f /opt/homebrew/bin/gh ]]; then
        original_gh="/opt/homebrew/bin/gh"
    elif [[ -f /usr/bin/gh ]]; then
        original_gh="/usr/bin/gh"
    else
        echo "gh is not installed"
        return 1
    fi

    local currently_logged_in_as_kara=false
    if [[ -n "$(${original_gh} auth status --active --json hosts | jq -r '.hosts["github.com"] | .[].login' | grep -i sophie-katz-kara)" ]]; then
        currently_logged_in_as_kara=true
    fi

    local current_repository_is_kara=false
    if [[ -n "$(git remote get-url origin | grep -i karaconnect)" ]]; then
        current_repository_is_kara=true
    fi

    if [[ "${currently_logged_in_as_kara}" == "true" ]] && [[ "${current_repository_is_kara}" == "false" ]]; then
        ${original_gh} auth switch --user sophie-iren-katz
    elif [[ "${currently_logged_in_as_kara}" == "false" ]] && [[ "${current_repository_is_kara}" == "true" ]]; then
        ${original_gh} auth switch --user sophie-katz-kara
    fi

    ${original_gh} "$@"
}
