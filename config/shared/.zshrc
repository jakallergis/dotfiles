# ~/.zshrc — symlinked from dotfiles/config/shared/.zshrc
#
# Two rules for this file:
#   * Installing is install.sh's job. This file only configures what is already
#     there, so every block is guarded and a missing tool is never an error.
#   * Section order matters, twice over: the p10k prompt has to come first, and
#     Homebrew has to come before anything that looks for a brew-installed tool.

# --- 1. powerlevel10k instant prompt ----------------------------------------
# Draws the prompt before the rest of this file runs. Anything that prints or
# asks for input must go ABOVE this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 2. Homebrew ------------------------------------------------------------
# Before sections 6 and 7 on purpose: a `command -v` cannot find a
# brew-installed tool until brew is on PATH, and the block would quietly do
# nothing. Defensive now that mise supplies everything probed below.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [[ -x $_brew ]] && eval "$($_brew shellenv)" && break
done
unset _brew

# --- 3. PATH ----------------------------------------------------------------
typeset -U path PATH # zsh keeps $path free of duplicates for us

# ~/.bun/bin is where `bun add -g` puts binaries (BUN_INSTALL defaults there)
# whatever supplies the bun binary itself — so it stays on PATH even though
# mise now installs bun. mise's shims are prepended later, so they still win.

for _dir in \
  "$HOME/.local/bin" \
  "$HOME/.lmstudio/bin" \
  "$HOME/.bun/bin" \
  "$HOME/.yarn/bin" \
  "$HOME/.config/yarn/global/node_modules/.bin" \
  "$HOME/.fzf/bin" \
  "$HOME/.druk/bin" \
  "$HOME/.atuin/bin"; do
  [[ -d $_dir ]] && path=("$_dir" $path)
done
unset _dir

# --- 4. oh-my-zsh -----------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"

# fpath has to grow BEFORE oh-my-zsh runs compinit, or nothing in here is found.
[[ -d $HOME/.custom_zsh_functions ]] && fpath=("$HOME/.custom_zsh_functions" $fpath)

# powerlevel10k when ./install.sh has cloned it; the stock theme otherwise, so
# a fresh checkout still gets a working prompt.
if [[ -d $ZSH/custom/themes/powerlevel10k ]]; then
  ZSH_THEME="powerlevel10k/powerlevel10k"
else
  ZSH_THEME="robbyrussell"
fi

ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
export UPDATE_ZSH_DAYS=13

plugins=(
    git
    gh
    node
    bun
    ssh
    kubectl
    docker
    aliases
    colored-man-pages
    command-not-found
    extract
    qrcode
    safe-paste
    sudo
)

# Not bundled with oh-my-zsh, so only when ./install.sh has cloned them.
# zsh-syntax-highlighting has to stay last in the list.
for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  [[ -d $ZSH/custom/plugins/$_plugin ]] && plugins+=("$_plugin")
done
unset _plugin

source $ZSH/oh-my-zsh.sh

# Prompt config, written by `p10k configure`. Kept as p10k's own line, verbatim:
# the wizard greps for it, and with anything else it appends a second copy —
# which lands in this repo, because ~/.zshrc is a symlink to it.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- 5. editor --------------------------------------------------------------
if command -v druk &>/dev/null; then
  export EDITOR=druk
else
  export EDITOR=vim
fi
export VISUAL=$EDITOR

autoload -Uz zmv

# Aliases and functions live in ~/.zshrc.d (section 7), so they can grow
# without this file growing. `g=git` comes from oh-my-zsh's git plugin.

# --- 6. tool init -----------------------------------------------------------
# mise: one version manager for node, bun and friends. Replaced nvm, whose
# nvm.sh cost ~600ms per shell and whose load-nvmrc hook forked on every cd.
#
# .nvmrc / .python-version / .ruby-version support is off by default in mise;
# it is switched on in the tracked ~/.config/mise/config.toml, not here, so
# there is one source of truth.
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# fzf must come BEFORE atuin: `fzf --zsh` binds Ctrl-R to its own history
# widget, and the atuin block below deliberately takes that key back. Ctrl-T
# (files) and Alt-C (cd) stay with fzf.
command -v fzf &>/dev/null && eval "$(fzf --zsh)"

if command -v atuin &>/dev/null; then
  export ATUIN_NOBIND="true"
  eval "$(atuin init zsh)"
  bindkey '^r' atuin-search
fi

# zoxide: `z <part of a path>` jumps, `zi` picks interactively (wants fzf).
# Add --cmd cd to the init call if you would rather it took over cd entirely.
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

# 1Password's SSH agent. Different socket per OS, and only if it is really
# there: pointing SSH_AUTH_SOCK at a missing socket is worse than leaving it
# unset, because ssh then fails instead of falling back to your key files.
for _sock in \
  "$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" \
  "$HOME/.1password/agent.sock"; do
  [[ -S $_sock ]] && export SSH_AUTH_SOCK=$_sock && break
done
unset _sock

# --- 7. drop-ins ------------------------------------------------------------
# Everything in ~/.zshrc.d is sourced in name order, last, so it can override
# anything above — key bindings included. That directory is a symlink to
# config/shared/.zshrc.d, so the files are tracked like any other dotfile.
#
# What goes in there: small, self-contained, stable plugins, vendored as single
# files with their upstream header intact. Anything with its own release cadence
# (p10k, zsh-syntax-highlighting) gets an install step and a git clone instead.
for _f in "$HOME"/.zshrc.d/*.zsh(N); do
  source "$_f"
done
unset _f

# --- 8. machine-local -------------------------------------------------------
# Untracked, so this is where tokens and per-machine settings go.
[[ -f $HOME/.zshrc.local ]] && source "$HOME/.zshrc.local"
