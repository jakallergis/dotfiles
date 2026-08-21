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
  cd "${repo:-$HOME/.dotfiles}"
}

# gclone <url> [dir] — clone a repo and step into it.
gclone() {
  [[ -n $1 ]] || { print -u2 'usage: gclone <url> [dir]'; return 1 }
  local dir=${2:-${${1##*/}%.git}}
  git clone "$1" "$dir" && cd -- "$dir"
}

# ahist [query…] — fuzzy picker over the whole history, every author, showing who
# ran each command and why. The selection lands on your next prompt, ready to
# edit or run; nothing is executed for you.
#
# Why not atuin's own picker: its interactive TUI (18.19) has no concept of
# author, agent or intent — checked the source — and ignores history_format and
# --format, which only apply to non-interactive listings. So atuin supplies the
# rows and fzf does the picking.
#
# Ctrl+R is deliberately untouched: atuin's interactive default author filter is
# $all-user, meaning non-agents, so it stays yours alone. Passing no --author
# here is what widens this to everyone — there is no $all value.

# One record per line, since fzf is line-oriented and agent commands are often
# multi-line. Newlines are encoded as a literal \n and decoded on selection.
_ahist_rows() {
  atuin search --limit "${AHIST_LIMIT:-500}" \
    --format '{time}|{author}|{intent}|{command}' "$@" |
    awk '
      # A new record starts at a timestamp; anything else is a continuation of a
      # multi-line command. Records are also emitted newest first: atuin picks
      # the most recent N but prints them oldest first, and -r reverses the
      # window rather than the order.
      /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] [0-9][0-9]:/ {
        if (rec != "") recs[++n] = rec; rec = $0; next
      }
      { rec = rec "\\n" $0 }
      END {
        if (rec != "") recs[++n] = rec
        for (i = n; i > 0; i--) print recs[i]
      }
    '
}

ahist() {
  command -v atuin &>/dev/null || { print -u2 'ahist: atuin is not installed'; return 1 }
  command -v fzf &>/dev/null || { print -u2 'ahist: needs fzf'; return 1 }

  local sel cmd
  sel=$(_ahist_rows "$@" | fzf \
    --no-sort --reverse --height 60% \
    --header 'all authors · enter puts the command on your prompt' \
    --preview 'printf "%b\n" {}' --preview-window 'down:4:wrap') || return 0

  cmd=${sel#*|*|*|}      # drop time|author|intent|
  cmd=${cmd//\\n/$'\n'} # decode the joined newlines
  [[ -n $cmd ]] && print -z -- "$cmd"
}
