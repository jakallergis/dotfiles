# Aliases.
#
# By the time this file loads, oh-my-zsh and its plugins have already defined
# ~400 aliases. Nothing here shadows one of those except where marked, and
# `als <word>` (aliases plugin) searches the lot if you are unsure.

# --- listing ----------------------------------------------------------------
# eza when it is installed, otherwise plain ls with per-OS colour flags.
if command -v eza &>/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza --long --all --group --git --group-directories-first'
  alias la='eza --all --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
elif [[ $OSTYPE == darwin* ]]; then
  alias ls='ls -FG'
  alias ll='ls -Alh'
  alias la='ls -A'
else
  alias ls='ls -F --color=auto'
  alias ll='ls -Alh'
  alias la='ls -A'
fi

# --- Debian package names ---------------------------------------------------
# apt ships these binaries renamed to avoid clashing with older packages.
command -v fd &>/dev/null || { command -v fdfind &>/dev/null && alias fd=fdfind; }
command -v bat &>/dev/null || { command -v batcat &>/dev/null && alias bat=batcat; }

# --- bun --------------------------------------------------------------------
alias b='bun'
alias bx='bunx'
alias br='bun run'
alias bi='bun install'

# --- git --------------------------------------------------------------------
# DELIBERATE SHADOW: oh-my-zsh's git plugin defines gc='git commit --verbose'.
# Its own "commit with a message" alias is gcmsg. Keeping muscle memory instead.
alias gc='git commit -m'
alias gs='git status' # free — omz uses gst

# --- editing ----------------------------------------------------------------
# Single-quoted so $EDITOR is resolved when run, not when this file is read.
alias zshc='$EDITOR ~/.zshrc'
alias vimc='$EDITOR ~/.vimrc'
alias omzshc='cd $ZSH/custom'
alias getpath='print -l $path'
alias k=kubectl
