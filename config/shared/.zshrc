#If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export TERM="xterm-256color"
export ZSH=~/.oh-my-zsh

test -d ~/.oh-my-zsh/custom/themes/powerlevel9k/
if [ $? -eq 1 ]
  then
    git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k;
fi

ZSH_THEME="powerlevel9k/powerlevel9k"
DEFAULT_USER=`whoami`

export UPDATE_ZSH_DAYS=1 # how often to auto-update (in days).
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git node)

source $ZSH/oh-my-zsh.sh

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.

# Example aliases
alias gs="git status"
alias gc="git commit -m"
alias g="git"
alias ls="ls -F"
alias la="ls -AF"
alias ll="ls -AlhF"
alias tnew="tmux new -s"
alias tatt="tmux a -t"
alias tls="tmux ls"
alias zshc="vim ~/.zshrc"
alias vimc="vim ~/.vimrc"
alias omzshc="vim ~/.oh-my-zsh"
alias getpath="print -l $path"
alias k=kubectl

# Include custom functions directory
fpath=(~/.custom_zsh_functions $fpath)
autoload -Uz zmv

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# place this after nvm initialization!
autoload -U add-zsh-hook

load-nvmrc() {
  local nvmrc_path
  nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version
    nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}

add-zsh-hook chpwd load-nvmrc
load-nvmrc

[ -d "$HOME/.atuin/bin" ] && export PATH="$HOME/.atuin/bin:$PATH"
if command -v atuin &>/dev/null; then
  export ATUIN_NOBIND="true"
  eval "$(atuin init zsh)"
  bindkey '^r' atuin-search
fi

export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if command -v pyenv &>/dev/null; then
    export PATH="$(pyenv root)/shims:$PATH"
    eval "$(pyenv init --path)"
fi

if command -v rbenv &>/dev/null; then
    eval "$(rbenv init -)"
fi

if [ -d /opt/homebrew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Added by LM Studio CLI (lms)
export PATH="$PATH:$HOME/.lmstudio/bin"
# End of LM Studio CLI section

# Created by `pipx` on 2025-08-09 11:29:18
export PATH="$PATH:$HOME/.local/bin"

# bun, managed by bum — bum activates the chosen version into ~/.bun/bin.
# The install steps deliberately stop both installers writing these lines here.
export BUM_INSTALL="$HOME/.bum"
[ -d "$BUM_INSTALL/bin" ] && export PATH="$BUM_INSTALL/bin:$PATH"
[ -d "$HOME/.bun/bin" ] && export PATH="$HOME/.bun/bin:$PATH"

# druk, a terminal editor
[ -d "$HOME/.druk/bin" ] && export PATH="$HOME/.druk/bin:$PATH"

# Machine-local settings and secrets. Untracked, so this is where tokens go.
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
