#!/bin/bash

set -e
set -u
set -o pipefail

DOTFILES_DIR="${HOME}/.dotfiles"

function ensure_dotfiles_cloned {
    if [[ ! -d "${DOTFILES_DIR}" ]]; then
        git clone https://github.com/sophie-iren-katz/dotfiles.git "${DOTFILES_DIR}"
    fi
}
