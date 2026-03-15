# History
setopt EXTENDED_HISTORY
setopt hist_ignore_all_dups
export HISTFILE=~/.zsh_history
export HISTSIZE=999999999
export SAVEHIST=$HISTSIZE

# Completions
export fpath=(~/.zsh/completions/ $fpath)
autoload -U compinit
compinit

# Plugins
if [[ -d /opt/homebrew ]]; then
    source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Prompt
eval "$(starship init zsh)"

# Homebrew
if [[ -d /opt/homebrew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    export PKG_CONFIG_PATH="/opt/homebrew/opt/pkg-config/lib/pkgconfig:/opt/homebrew/opt/mysql-client/lib/pkgconfig"
fi

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
if command -v eza >/dev/null 2>&1; then
    alias ls='eza'
fi

# Additional scripts
. ~/.zsh/bitch.zsh
. ~/.zsh/claude.zsh
. ~/.zsh/dotfiles.zsh
. ~/.zsh/git.zsh

# Path
export PATH="/usr/local/go/bin:$(go env GOPATH)/bin:/opt/homebrew/opt/llvm/bin:/opt/mysql/bin:${PATH}"

if command -v brew >/dev/null 2>&1; then
    export PATH="$(brew --prefix)/opt/python@3.11/libexec/bin:${PATH}"
fi

export MYSQLCLIENT_LDFLAGS="-L/opt/homebrew/opt/mysql-client/lib"
export MYSQLCLIENT_CFLAGS="-I/opt/homebrew/opt/mysql-client/include/mysql"

# Go private
export GOPRIVATE='github.com/sophie-iren-katz/*'

# bun completions
[ -s "/Users/sophie/.bun/_bun" ] && source "/Users/sophie/.bun/_bun"

# thefuck
if command -v thefuck >/dev/null 2>&1; then
    eval $(thefuck --alias)
fi

# Keybindings
bindkey "^[^[[C" forward-word
bindkey "^[^[[D" backward-word
bindkey '\e[H'  beginning-of-line
bindkey '\eOH'  beginning-of-line
bindkey '\e[F'  end-of-line
bindkey '\eOF'  end-of-line

# Keys
if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN}" ]]; then
    export GITHUB_PERSONAL_ACCESS_TOKEN="$(security find-generic-password -a $USER -s github-token -w 2>/dev/null)"
fi

ssh-add ~/.ssh/id_ed25519_personal >/dev/null 2>&1
ssh-add ~/.ssh/id_ed25519_karaconnect >/dev/null 2>&1

# Ctrl
export CTRL_NO_OPEN=1

# zoxide (must be last)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --cmd cd)"
    export _ZO_DOCTOR=0
fi
