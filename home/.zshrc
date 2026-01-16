# =============================================================================
# 1. P10K INSTANT PROMPT (Must be at the very top)
# =============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# =============================================================================
# 2. ZINIT MANAGER (Plugin Manager)
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# 3. ENVIRONMENT & PATH
# =============================================================================
export EDITOR="nvim"
export VISUAL="nvim"
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

# XDG Standards
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Clean Path Management (typeset -U prevents duplicates)
typeset -U path
path=(
    "$HOME/.scripts"
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.cargo/bin"
    "$HOME/.npm-global/bin"
    "$HOME/Dev/Tools/flutter/bin"
    "/opt/cuda/bin"
    $path
)
export PATH

# Utils
export BAT_THEME="TwoDark"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="
--preview 'bat -n --color=always {}'
--bind 'ctrl-/:change-preview-window(down|hidden|)'
"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

export CUDA_HOME=/opt/cuda
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/lib64

# =============================================================================
# 4. PLUGINS (Order Matters!)
# =============================================================================

# 1. Completions must be added to fpath BEFORE compinit
zinit light zsh-users/zsh-completions

# 2. Initialize completion system
autoload -Uz compinit
# Check if dump file is older than 24h, if so regenerate (faster startup)
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# 3. Syntax Highlighting & Autosuggestions (Must be AFTER compinit)
# using fast-syntax-highlighting (faster than zsh-users version)
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-history-substring-search

# =============================================================================
# 5. OPTIONS & KEYBINDINGS
# =============================================================================
setopt SHARE_HISTORY          # Share history between terminals
setopt HIST_IGNORE_ALL_DUPS   # Clean history
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks
setopt AUTO_CD                # cd by typing directory name
setopt ALWAYS_TO_END          # Move cursor to end of completed word

bindkey -v # Vim mode

# History Search (Up/Down Arrows to search what you typed)
bindkey "^[[A" history-substring-search-up
bindkey "^[[B" history-substring-search-down
bindkey -M vicmd "k" history-substring-search-up
bindkey -M vicmd "j" history-substring-search-down

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Edit current command in $EDITOR (Ctrl+e)
autoload -z edit-command-line
zle -N edit-command-line
bindkey "^e" edit-command-line

# =============================================================================
# 6. TOOL INITIALIZATION
# =============================================================================

# Mise (Version Manager)
eval "$(mise activate zsh)"

# FZF (Fuzzy Finder)
source <(fzf --zsh)

# UV (Python tools)
# Generate these only if commands exist to prevent errors on new machines
(( $+commands[uv] )) && eval "$(uv generate-shell-completion zsh)"
(( $+commands[uvx] )) && eval "$(uvx --generate-shell-completion zsh)"

# Zoxide (Better CD)
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
  alias cd="z"
fi

# =============================================================================
# 7. ALIASES & FUNCTIONS
# =============================================================================
alias sz="source ~/.zshrc"

# Modern LS
if (( $+commands[eza] )); then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza --icons -l --group-directories-first --git"
  alias la="eza --icons -la --group-directories-first --git"
  alias lt="eza --tree --level=2 --icons"
else
  alias ls="ls --color=auto"
  alias ll="ls -l"
  alias la="ls -la"
fi

# Safety
alias cp="cp -i"
alias mv="mv -i"
alias rm="rm -i"
alias grep="rg --color=auto"

# Utils
alias df="df -h"
alias free="free -m"
alias vim="nvim"

# Yazi Function (Shell wrapper)
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d "" cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# =============================================================================
# 8. THEME & FINALIZATION
# =============================================================================

# Powerlevel10k Theme
zinit ice depth=1
zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh



. "$HOME/.local/share/../bin/env"

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

path=('/home/hhyurdagul/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<
