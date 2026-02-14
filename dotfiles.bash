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

        # Copy files from filesystem into the dotfiles repo
        cp -v ~/.zshrc "${DOTFILES_DIR}/.zshrc"
        cp -v ~/.aerospace.toml "${DOTFILES_DIR}/.aerospace.toml"
        cp -v ~/.gitconfig "${DOTFILES_DIR}/.gitconfig"
        cp -v ~/.gitconfig-karaconnect "${DOTFILES_DIR}/.gitconfig-karaconnect"
        cp -v ~/.config/kitty/kitty.conf "${DOTFILES_DIR}/.config/kitty/kitty.conf"
        cp -v ~/.config/mpv/mpv.conf "${DOTFILES_DIR}/.config/mpv/mpv.conf"
        cp -v ~/.config/starship.toml "${DOTFILES_DIR}/.config/starship.toml"
        ;;
    load)
        # Make directories if needed
        mkdir -p "${HOME}/.config/kitty"
        mkdir -p "${HOME}/.config/mpv"

        # Copy files from dotfiles repo into the filesystem
        cp -v "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
        cp -v "${DOTFILES_DIR}/.aerospace.toml" "${HOME}/.aerospace.toml"
        cp -v "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
        cp -v "${DOTFILES_DIR}/.gitconfig-karaconnect" "${HOME}/.gitconfig-karaconnect"
        cp -v "${DOTFILES_DIR}/.config/kitty/kitty.conf" "${HOME}/.config/kitty/kitty.conf"
        cp -v "${DOTFILES_DIR}/.config/mpv/mpv.conf" "${HOME}/.config/mpv/mpv.conf"
        cp -v "${DOTFILES_DIR}/.config/starship.toml" "${HOME}/.config/starship.toml"
        ;;
    *)
        echo "error: invalid command ${1}"
        echo
        usage
        exit 1
        ;;
esac
