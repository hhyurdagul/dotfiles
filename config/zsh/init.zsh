# Interactive zsh setup (sourced via programs.zsh.initContent, order 1000).
# Completions, autosuggestions, syntax highlighting, substring search, and the
# powerlevel10k theme itself are wired declaratively in home/hhyurdagul/default.nix.

# Personal scripts first; `typeset -U path` from Home Manager drops duplicates.
path=("$HOME/.scripts" "$HOME/.local/bin" $path)
export PATH

# Pager and finder previews (bat/eza/fd come from home.packages).
export BAT_THEME="TwoDark"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--preview 'bat -n --color=always {}'
--bind 'ctrl-/:change-preview-window(down|hidden|)'
"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

# Local CUDA install, kept off PATH on purpose.
export CUDA_HOME=/opt/cuda
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/lib64

# History/word options with no Home Manager knob
# (share/ignore-dups/autocd come from programs.zsh options).
setopt HIST_REDUCE_BLANKS ALWAYS_TO_END

# Up/Down substring search is wired by programs.zsh.historySubstringSearch;
# these add the same for vi command mode.
bindkey -M vicmd "k" history-substring-search-up
bindkey -M vicmd "j" history-substring-search-down

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Edit current command in $EDITOR (Ctrl+e).
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^e" edit-command-line

# Tool integrations. Each is guarded so a missing binary degrades to stock zsh.
# shellcheck disable=SC1090
(($+commands[fzf])) && source <(fzf --zsh)

(($+commands[uv])) && eval "$(uv generate-shell-completion zsh)"
(($+commands[uvx])) && eval "$(uvx --generate-shell-completion zsh)"

if (($+commands[zoxide])); then
	eval "$(zoxide init zsh)"
	alias cd="z"
fi

# Reload this config after `nixos-rebuild switch` regenerates it.
alias sz='source "$ZDOTDIR/.zshrc"'

if (($+commands[eza])); then
	alias ls="eza --icons --group-directories-first"
	alias ll="eza --icons -l --group-directories-first --git"
	alias la="eza --icons -la --group-directories-first --git"
	alias lt="eza --tree --level=2 --icons"
else
	alias ls="ls --color=auto"
	alias ll="ls -l"
	alias la="ls -la"
fi

alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"

alias df="df -h"
alias free="free -m"
alias vim=hx
alias nvim=hx
alias todo="hx ~/Dev/todo.md"

# Powerlevel10k configuration (managed as ~/.p10k.zsh).
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
