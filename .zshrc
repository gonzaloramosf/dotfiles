# history
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history
setopt share_history
setopt hist_ignore_dups

# completion
autoload -Uz compinit
compinit

# complete case-insensitively, so `cd desk<Tab>` can complete to `Desktop`
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# show the current branch when inside a git repository
autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' (%F{cyan}%b%f)'
precmd() { vcs_info }
setopt prompt_subst
PROMPT='%F{green}%n@%m%f %F{blue}%~%f${vcs_info_msg_0_} %# '

# aliases
if (( $+commands[gls] )); then
  alias ls='gls -lah --color=always --group-directories-first'
elif [[ "$OSTYPE" == darwin* ]]; then
  alias ls='ls -lahG'
else
  alias ls='ls -lah --color=auto --group-directories-first'
fi

alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
alias vim='nvim'
alias ..='cd ..'
alias ...='cd ../..'
if (( $+commands[caffeinate] )); then
  alias caffeine='caffeinate -d -i -m -s'
fi
