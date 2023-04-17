# If not running interactively, don't do anything
[[ $- != *i* ]] && return

export XDG_CONFIG_HOME="$HOME/.config"

## Vim-like keys
#set -o vi
#PS0="\e[2 q"

## Bin directories
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.config/cargo/bin"

## Editor variable

# If Neovim is installed
if hash "nvim" &> /dev/null; then
  if hash "lvim" &> /dev/null; then
    export EDITOR="lvim"
  else
    export EDITOR="nvim"
  fi
  # Neovim-remote editing support
  if hash "nvr" &> /dev/null; then
    export NVR_CMD=$EDITOR
    export EDITOR="nvr -s --remote"
  fi
# If Neovim is not installed
elif hash "vim" &> /dev/null; then
  export EDITOR="vim"
elif hash "vi" &> /dev/null; then
  export EDITOR="vi"
elif hash "nano" &> /dev/null; then
  export EDITOR="nano"
fi

export VISUAL=$EDITOR

## Prompt
if hash "starship" &> /dev/null; then
  export STARSHIP_CONFIG="$HOME/.starshiprc"
  eval "$(starship init bash)"
else
  PS1='\n \[\e[0;1m\]\u\[\e[0m\]@\[\e[0;1;96m\]\h\[\e[0m\]:\[\e[0m\]\w 
  > '
fi

## Rust
export CARGO_HOME="$HOME/.config/cargo"

## Better file listing
if hash "exa" &> /dev/null; then
  export LS="exa --icons --group-directories-first"
else
  export LS="ls -h --color"
fi

# aliases
alias e=$EDITOR
alias ls="$LS"
alias ll="ls -l"
alias la="ls -A"
alias lla="ls -lA"
. "/var/home/opticaldisc/.config/cargo/env"
