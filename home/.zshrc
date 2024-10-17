#!/bin/sh

bindkey '^[^?' backward-kill-word
bindkey "\e[1;3D" backward-word     # ⌥←
bindkey "\e[1;3C" forward-word      # ⌥→
bindkey "^[[1;9D" beginning-of-line # cmd+←
bindkey "^[[1;9C" end-of-line       # cmd+→

setopt appendhistory
export HISTSIZE=10000
export SAVEHIST=10000
export HISTFILE="$HOME/.zsh_history"

export EDITOR=nvim
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.scripts:$PATH"

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"


alias sz="source ~/.zshrc"

alias todo="nvim ~/Programming/todo.md"
alias p="source ~/Programming/Python/main/bin/activate"
alias ptenv="source ~/Programming/Python/project-team/bin/activate"

alias ls=eza
alias ll="ls -l"
alias la="ls -a"
alias lla="ls -la"

# Colorize grep output (good for log files)
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# confirm before overwriting something
alias cp="cp -i"
alias mv='mv -i'
alias rm='rm -i'

# easier to read disk
alias df='df -h'     # human-readable sizes
alias free='free -m' # sh

# Git aliasses
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
autoload -U compinit && compinit

bindkey -v

KEYTIMEOUT=1


eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

source <(fzf --zsh)

type starship_zle-keymap-select >/dev/null || eval "$(starship init zsh)"
