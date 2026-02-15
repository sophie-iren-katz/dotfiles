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
        mkdir -p "${DOTFILES_DIR}/.config/kitty"
        mkdir -p "${DOTFILES_DIR}/.config/mpv"
        mkdir -p "${DOTFILES_DIR}/.zsh"
        mkdir -p "${DOTFILES_DIR}/.zsh/completions"

        # Copy files from filesystem into the dotfiles repo
        cp -v ~/.zshrc "${DOTFILES_DIR}/.zshrc"
        cp -v ~/.aerospace.toml "${DOTFILES_DIR}/.aerospace.toml"
        cp -v ~/.gitconfig "${DOTFILES_DIR}/.gitconfig"
        cp -v ~/.gitconfig-karaconnect "${DOTFILES_DIR}/.gitconfig-karaconnect"
        cp -v ~/.config/kitty/kitty.conf "${DOTFILES_DIR}/.config/kitty/kitty.conf"
        cp -v ~/.config/mpv/mpv.conf "${DOTFILES_DIR}/.config/mpv/mpv.conf"
        cp -v ~/.config/starship.toml "${DOTFILES_DIR}/.config/starship.toml"
        cp -v ~/.zsh/bitch.zsh "${DOTFILES_DIR}/.zsh/bitch.zsh"
        cp -v ~/.zsh/dotfiles.zsh "${DOTFILES_DIR}/.zsh/dotfiles.zsh"
        cp -v ~/.zsh/git.zsh "${DOTFILES_DIR}/.zsh/git.zsh"
        cp -v ~/.zsh/completions/_gadd "${DOTFILES_DIR}/.zsh/completions/_gadd"
        cp -v ~/.zsh/completions/_gsta "${DOTFILES_DIR}/.zsh/completions/_gsta"
        cp -v ~/.zsh/completions/_gsub "${DOTFILES_DIR}/.zsh/completions/_gsub"
        cp -v ~/.zsh/completions/_gunadd "${DOTFILES_DIR}/.zsh/completions/_gunadd"

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
        mkdir -p "${HOME}/.config/kitty"
        mkdir -p "${HOME}/.config/mpv"
        mkdir -p "${HOME}/.zsh"
        mkdir -p "${HOME}/.zsh/completions"

        # Copy files from dotfiles repo into the filesystem
        cp -v "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
        cp -v "${DOTFILES_DIR}/.aerospace.toml" "${HOME}/.aerospace.toml"
        cp -v "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
        cp -v "${DOTFILES_DIR}/.gitconfig-karaconnect" "${HOME}/.gitconfig-karaconnect"
        cp -v "${DOTFILES_DIR}/.config/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
        cp -v "${DOTFILES_DIR}/.config/mpv/mpv.conf" "${HOME}/.config/mpv/mpv.conf"
        cp -v "${DOTFILES_DIR}/.config/starship.toml" "${HOME}/.config/starship.toml"
        cp -v "${DOTFILES_DIR}/.zsh/bitch.zsh" "${HOME}/.zsh/bitch.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/dotfiles.zsh" "${HOME}/.zsh/dotfiles.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/git.zsh" "${HOME}/.zsh/git.zsh"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gadd" "${HOME}/.zsh/completions/_gadd"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gsta" "${HOME}/.zsh/completions/_gsta"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gsub" "${HOME}/.zsh/completions/_gsub"
        cp -v "${DOTFILES_DIR}/.zsh/completions/_gunadd" "${HOME}/.zsh/completions/_gunadd"
        ;;
    *)
        echo "error: invalid command ${1}"
        echo
        usage
        exit 1
        ;;
esac
