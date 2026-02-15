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
source /opt/homebrew/share/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

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

# Additional scripts
. ~/.zsh/bitch.zsh
. ~/.zsh/dotfiles.zsh
. ~/.zsh/git.zsh

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
