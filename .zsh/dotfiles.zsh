function dotfiles {
    if [[ ! -d "${HOME}/.dotfiles" ]]; then
        git clone https://github.com/sophie-iren-katz/dotfiles.git "${HOME}/.dotfiles"
    fi

    cd "${HOME}/.dotfiles"
    ./dotfiles.bash "$@"
}
