# Plugins
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# History
setopt EXTENDED_HISTORY
setopt hist_ignore_all_dups
export HISTFILE=~/.zsh_history
export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE

# Prompt
eval "$(starship init zsh)"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"
export PKG_CONFIG_PATH="/opt/homebrew/opt/pkg-config/lib/pkgconfig:/opt/homebrew/opt/mysql-client/lib/pkgconfig"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Node.JS
export NODE_OPTIONS="--max-old-space-size=8192"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$HOME/.local/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Poetry
export POETRY_VIRTUALENVS_CREATE=1
export POETRY_VIRTUALENVS_IN_PROJECT=1

# Cargo
. "$HOME/.cargo/env"

# Aliases
alias ls='eza'

# Bitch
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

# Git aliases

# Show one line status of all submodules
function gitsm {
    # Show status of root repository if clean
    local root_changes=$(git status --porcelain)
    local root_dirname=$(basename $(pwd))
    
    if [[ -z "${root_changes}" ]]; then
        echo "\033[2;32m$root_dirname\033[0;0m"
    fi
    
    # Show status of all clean submodules
    git submodule foreach --quiet '
        changes=$(git status --porcelain)
        if [[ -z "${changes}" ]]; then
            echo "\033[2;32m$path\033[0;0m"
        fi
    '

    # Show status of root repository if dirty
    if [[ -n "${root_changes}" ]]; then
        echo "\033[1;33m${root_dirname} *\033[0;0m"
    fi

    # Show status of all dirty submodules
    git submodule foreach --quiet '
        changes=$(git status --porcelain)
        if [[ -n "${changes}" ]]; then
            echo "\033[1;33m$path *\033[0;0m"
        fi
    '
}

# Show changes in all submodules
function gitch {
    # Show status of root repository
    local root_changes=$(git status --porcelain)
    local root_dirname=$(basename $(pwd))
    
    if [[ -n "${root_changes}" ]]; then
        echo "\033[1;33m${root_dirname}\033[0;0m"
        echo "$root_changes" | sed -E "
            s/^ M /  \x1b[0;33mM\x1b[0m /; t
            s/^M /  \x1b[0;32mA\x1b[0m /; t
            s/^ D /  \x1b[2;31mD\x1b[0m /; t
            s/^D /  \x1b[0;31mD\x1b[0m /; t
            s/^\?\? /  \x1b[0;36mU\x1b[0m /; t
            s/^UU /  \x1b[0;31mU\x1b[0m /; t
            s/^ /  /
        "
        echo
    fi

    # Show status of all dirty submodules
    git submodule foreach --quiet '
        changes=$(git status --porcelain)
        if [[ -n "${changes}" ]]; then
            echo "\033[1;33m${path}\033[0;0m"
            echo "$changes" | sed -E "
                s/^ M /  \x1b[0;33mM\x1b[0m /; t
                s/^M /  \x1b[0;32mA\x1b[0m /; t
                s/^ D /  \x1b[2;31mD\x1b[0m /; t
                s/^D /  \x1b[0;31mD\x1b[0m /; t
                s/^\?\? /  \x1b[0;36mU\x1b[0m /; t
                s/^UU /  \x1b[0;31mU\x1b[0m /; t
                s/^ /  /
            "
            echo
        fi
    '
}

# Stage all changes in current repository
function gita {
    git add --all .
    
    local changes=$(git status --porcelain)
    echo "$changes" | sed -E "
        s/^ M /\x1b[0;33mM\x1b[0m /; t
        s/^M /\x1b[0;32mA\x1b[0m /; t
        s/^ D /\x1b[2;31mD\x1b[0m /; t
        s/^D /\x1b[0;31mD\x1b[0m /; t
        s/^\?\? /\x1b[0;36mU\x1b[0m /; t
        s/^UU /\x1b[0;31mU\x1b[0m /; t
        s/^ //
    "
}

# Unstage all changes in current repository
function gitua {
    git restore --staged .

    local changes=$(git status --porcelain)
    echo "$changes" | sed -E "
        s/^ M /\x1b[0;33mM\x1b[0m /; t
        s/^M /\x1b[0;32mA\x1b[0m /; t
        s/^ D /\x1b[2;31mD\x1b[0m /; t
        s/^D /\x1b[0;31mD\x1b[0m /; t
        s/^\?\? /\x1b[0;36mU\x1b[0m /; t
        s/^UU /\x1b[0;31mU\x1b[0m /; t
        s/^ //
    "
}

# Stage and commit all changes in current repository
function gitc {
    git status
    echo
    git add --all .
    echo
    git commit -m "$*"
}

# Undo last commit in current repository
function gituc {
    git reset HEAD~1
    echo
    git status
}

# Reset all changes in current repository
function gitr {
    git reset --hard HEAD
    echo
    git pull
    echo
    git status
}

# Stage, commit, and push all changes in current repository
function gitcp {
    gitc "$*"
    echo
    git push -u origin HEAD
}

# Diff changes in current repository using Cursor
function gitd {
    git difftool --no-prompt $*
}

# Create a branch, checkout, and push
function gitb {
    git branch "${1}"
    echo
    git checkout "${1}"
}

# Checkout and pull a branch
function gitco {
    git checkout "${1}"
    git pull
}

# Migrate changes to another branch
function gitmg {
    git stash
    git checkout "${1}"
    git pull
    git stash pop
}

# Print help for git aliases
function githelp {
    echo "gitsm   -- Show one line status of all submodules"
    echo "gitch   -- Show changes in all submodules"
    echo "gita    -- Stage all changes in current repository"
    echo "gitua   -- Unstage all changes in current repository"
    echo "gitc    -- Stage, commit, and push all changes in current repository"
    echo "gituc   -- Undo last commit in current repository"
    echo "gitr    -- Reset all changes in current repository"
    echo "gitcp   -- Stage, commit, and push all changes in current repository"
    echo "gitd    -- Diff changes in current repository using Cursor"
    echo "gitb    -- Create a branch, checkout, and push"
    echo "gitco   -- Checkout and pull a branch"
    echo "gitmg   -- Migrate changes to another branch"
    echo "githelp -- Print help for git aliases"
}

# Path
export PATH="/usr/local/go/bin:$(go env GOPATH)/bin:/opt/homebrew/opt/llvm/bin:$(brew --prefix)/opt/python@3.11/libexec/bin:/opt/mysql/bin:${PATH}"
export MYSQLCLIENT_LDFLAGS="-L/opt/homebrew/opt/mysql-client/lib"
export MYSQLCLIENT_CFLAGS="-I/opt/homebrew/opt/mysql-client/include/mysql"

# Go private
export GOPRIVATE='github.com/sophie-lund/*'
export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# bun completions
[ -s "/Users/sophie/.bun/_bun" ] && source "/Users/sophie/.bun/_bun"

# Keybindings
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word
bindkey '\e[H'  beginning-of-line
bindkey '\eOH'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\eOF'  end-of-line

# Dotfiles
function dotfiles {
    
}
