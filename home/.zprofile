# Zprofile
# Environment variables and paths are managed in .zshrc
. "$HOME/.cargo/env"

. "$HOME/.local/bin/env"

[[ ! -r "$HOME/.opam/opam-init/init.zsh" ]] || source "$HOME/.opam/opam-init/init.zsh" >/dev/null 2>/dev/null
