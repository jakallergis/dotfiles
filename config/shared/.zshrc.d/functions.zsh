# Functions.
#
# No `extract` here on purpose — the oh-my-zsh extract plugin already provides it.

# mkcd <dir> — create a directory (with parents) and step into it.
mkcd() {
  [[ -n $1 ]] || { print -u2 'usage: mkcd <dir>'; return 1 }
  mkdir -p -- "$1" && cd -- "$1"
}

# killport <port…> — kill whatever is listening on a TCP port. The one you
# reach for when a dev server did not let go of 3000.
killport() {
  [[ -n $1 ]] || { print -u2 'usage: killport <port> [port…]'; return 1 }
  local port pids
  for port in "$@"; do
    if command -v lsof &>/dev/null; then
      pids=$(lsof -ti "tcp:$port" 2>/dev/null)
      if [[ -z $pids ]]; then
        print "nothing listening on $port"
        continue
      fi
      print "killing ${(j:, :)${(f)pids}} on port $port"
      print -l $pids | xargs kill -9 2>/dev/null
    elif command -v fuser &>/dev/null; then
      fuser -k "$port/tcp" 2>/dev/null || print "nothing listening on $port"
    else
      print -u2 'killport needs lsof or fuser'
      return 1
    fi
  done
}

# dots — jump to the dotfiles repo, found by following ~/.zshrc rather than
# hardcoding a path, so it works wherever the repo is cloned.
dots() {
  local repo
  if [[ -L $HOME/.zshrc ]]; then
    repo=$(readlink "$HOME/.zshrc")   # …/dotfiles/config/shared/.zshrc
    repo=${repo:h:h:h}
  fi
  cd "${repo:-$HOME/dotfiles}"
}

# gclone <url> [dir] — clone a repo and step into it.
gclone() {
  [[ -n $1 ]] || { print -u2 'usage: gclone <url> [dir]'; return 1 }
  local dir=${2:-${${1##*/}%.git}}
  git clone "$1" "$dir" && cd -- "$dir"
}
