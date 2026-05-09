#!/bin/bash

# Safety flags
set -e
set -u
set -o pipefail

# Resolve dotfiles directory for this repo
DOTFILES_DIR="${HOME}/.dotfiles"

# Functions
function usage {
    echo "usage: bash dotfiles.bash <command>"
    echo
    echo "where <command> is one of:"
    echo "  save -- Save dotfiles from the filesystem into the dotfiles repo"
    echo "  load -- Load dotfiles from the dotfiles repo onto the filesystem"
}

if [[ -z "${1:-}" ]]; then
    echo "error: command is required"
    echo
    usage
    exit 1
fi

# Make sure it's cloned
if [[ ! -d "${DOTFILES_DIR}" ]]; then
    git clone https://github.com/sophie-iren-katz/dotfiles.git "${DOTFILES_DIR}"
fi

case "${1}" in
    save)
        # Make directories if needed
        mkdir -p "${DOTFILES_DIR}/.claude/hooks"
        mkdir -p "${DOTFILES_DIR}/.config/kitty"
        mkdir -p "${DOTFILES_DIR}/.config/mpv"
        mkdir -p "${DOTFILES_DIR}/.zsh"
        mkdir -p "${DOTFILES_DIR}/.zsh/completions"

        # Copy files from filesystem into the dotfiles repo
        cp -v "${HOME}/.zshrc" "${DOTFILES_DIR}/.zshrc"
        cp -v "${HOME}/.hushlogin" "${DOTFILES_DIR}/.hushlogin"
        cp -v "${HOME}/.aerospace.toml" "${DOTFILES_DIR}/.aerospace.toml"
        cp -v "${HOME}/.gitconfig" "${DOTFILES_DIR}/.gitconfig"
        cp -v "${HOME}/.gitconfig-karaconnect" "${DOTFILES_DIR}/.gitconfig-karaconnect"
        cp -v "${HOME}/.config/kitty/kitty.conf" "${DOTFILES_DIR}/.config/kitty/kitty.conf"
        cp -v "${HOME}/.config/kitty/new_tab_inherit.py" "${DOTFILES_DIR}/.config/kitty/new_tab_inherit.py"
        cp -v "${HOME}/.config/kitty/notification_watcher.py" "${DOTFILES_DIR}/.config/kitty/notification_watcher.py"
        cp -v "${HOME}/.config/mpv/mpv.conf" "${DOTFILES_DIR}/.config/mpv/mpv.conf"
        cp -v "${HOME}/.config/starship.toml" "${DOTFILES_DIR}/.config/starship.toml"
        cp -v "${HOME}/.zsh/bitch.zsh" "${DOTFILES_DIR}/.zsh/bitch.zsh"
        cp -v "${HOME}/.zsh/claude.zsh" "${DOTFILES_DIR}/.zsh/claude.zsh"
        cp -v "${HOME}/.zsh/dotfiles.zsh" "${DOTFILES_DIR}/.zsh/dotfiles.zsh"
        cp -v "${HOME}/.zsh/git.zsh" "${DOTFILES_DIR}/.zsh/git.zsh"
        cp -v "${HOME}/.zsh/kitty.zsh" "${DOTFILES_DIR}/.zsh/kitty.zsh"
        cp -v "${HOME}/.zsh/completions/_gadd" "${DOTFILES_DIR}/.zsh/completions/_gadd"
        cp -v "${HOME}/.zsh/completions/_gsta" "${DOTFILES_DIR}/.zsh/completions/_gsta"
        cp -v "${HOME}/.zsh/completions/_gsub" "${DOTFILES_DIR}/.zsh/completions/_gsub"
        cp -v "${HOME}/.zsh/completions/_gunadd" "${DOTFILES_DIR}/.zsh/completions/_gunadd"
        cp -v "${HOME}/.claude/CLAUDE.md" "${DOTFILES_DIR}/.claude/CLAUDE.md"
        cp -v "${HOME}/.claude/settings.json" "${DOTFILES_DIR}/.claude/settings.json"
        cp -v "${HOME}/.claude/hooks/guard-aws-role.sh" "${DOTFILES_DIR}/.claude/hooks/guard-aws-role.sh"
        cp -v "${HOME}/.claude/hooks/guard-destructive.sh" "${DOTFILES_DIR}/.claude/hooks/guard-destructive.sh"
        cp -v "${HOME}/.claude/hooks/guard-protected-paths.sh" "${DOTFILES_DIR}/.claude/hooks/guard-protected-paths.sh"
        cp -v "${HOME}/.claude/hooks/notify-on-event.sh" "${DOTFILES_DIR}/.claude/hooks/notify-on-event.sh"
        cp -v "${HOME}/.claude/hooks/notify-on-stop.sh" "${DOTFILES_DIR}/.claude/hooks/notify-on-stop.sh"
        cp -v "${HOME}/.claude/hooks/notify.sh" "${DOTFILES_DIR}/.claude/hooks/notify.sh"

        # Notify the user what to do next
        echo
        echo "$ cd ${DOTFILES_DIR}"
        echo "$ git add -A ."
        echo "$ git commit -m \"<message>\""
        echo "$ git push"
        ;;
    load)
        # Make sure to pull latest
        git pull

        # Make directories if needed
        mkdir -p "${HOME}/.claude/hooks"
        mkdir -p "${HOME}/.config/kitty"
        mkdir -p "${HOME}/.config/mpv"
        mkdir -p "${HOME}/.zsh"
        mkdir -p "${HOME}/.zsh/completions"

        # Copy files from dotfiles repo into the filesystem
        cp -v "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
        cp -v "${DOTFILES_DIR}/.hushlogin" "${HOME}/.hushlogin"
        cp -v "${DOTFILES_DIR}/.aerospace.toml" "${HOME}/.aerospace.toml"
        cp -v "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
        cp -v "${DOTFILES_DIR}/.gitconfig-karaconnect" "${HOME}/.gitconfig-karaconnect"
        cp -v "${DOTFILES_DIR}/.config/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
        cp -v "${DOTFILES_DIR}/.config/kitty/new_tab_inherit.py" "${HOME}/.config/kitty/new_tab_inherit.py"
        cp -v "${DOTFILES_DIR}/.config/kitty/notification_watcher.py" "${HOME}/.config/kitty/notification_watcher.py"
        cp -v "${DOTFILES_DIR}/.config/mpv/mpv.conf" "${HOME}/.config/mpv/mpv.conf"
        cp -v "${DOTFILES_DIR}/.config/starship.toml" "${HOME}/.config/starship.toml"
        cp -v "${DOTFILES_DIR}/.zsh/bitch.zsh" "${HOME}/.zsh/bitch.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/claude.zsh" "${HOME}/.zsh/claude.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/dotfiles.zsh" "${HOME}/.zsh/dotfiles.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/git.zsh" "${HOME}/.zsh/git.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/kitty.zsh" "${HOME}/.zsh/kitty.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gadd" "${HOME}/.zsh/completions/_gadd"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gsta" "${HOME}/.zsh/completions/_gsta"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gsub" "${HOME}/.zsh/completions/_gsub"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gunadd" "${HOME}/.zsh/completions/_gunadd"
        cp -v "${DOTFILES_DIR}/.claude/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
        cp -v "${DOTFILES_DIR}/.claude/settings.json" "${HOME}/.claude/settings.json"
        cp -v "${DOTFILES_DIR}/.claude/hooks/guard-aws-role.sh" "${HOME}/.claude/hooks/guard-aws-role.sh"
        cp -v "${DOTFILES_DIR}/.claude/hooks/guard-destructive.sh" "${HOME}/.claude/hooks/guard-destructive.sh"
        cp -v "${DOTFILES_DIR}/.claude/hooks/guard-protected-paths.sh" "${HOME}/.claude/hooks/guard-protected-paths.sh"
        cp -v "${DOTFILES_DIR}/.claude/hooks/notify-on-event.sh" "${HOME}/.claude/hooks/notify-on-event.sh"
        cp -v "${DOTFILES_DIR}/.claude/hooks/notify-on-stop.sh" "${HOME}/.claude/hooks/notify-on-stop.sh"
        cp -v "${DOTFILES_DIR}/.claude/hooks/notify.sh" "${HOME}/.claude/hooks/notify.sh"
        ;;
    *)
        echo "error: invalid command ${1}"
        echo
        usage
        exit 1
        ;;
esac
