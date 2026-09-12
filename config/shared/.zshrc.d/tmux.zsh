# tmux — sessions that outlive the connection.
#
# The idea in one line: on a machine you reach over the network, a shell should
# belong to the machine, not to the connection. Start something, shut the
# laptop, ssh back tomorrow, find it still running.
#
# tmux itself comes from mise (see config/shared/.config/mise/config.toml) and
# its configuration from ~/.config/tmux/tmux.conf. Only the two pieces that have
# to live in the shell are here: the `t` command, and the auto-attach.

command -v tmux &>/dev/null || return

# _tmux_free_session — the session you were last in that nobody is sitting in.
#
# Two ssh connections to the same box both ran `tmux attach`, which takes the
# most recently used session whether or not a client is already on it. Two
# clients on one session is a genuinely bad place to be: they share a current
# window, so moving in one moves the other, and the window is sized for both at
# once. So the rule is "resume what I left, unless someone is already in it" —
# a dropped connection still lands back in its own work, a second connection
# gets its own.
_tmux_free_session() {
  tmux list-sessions -F '#{session_attached} #{session_last_attached} #{session_name}' 2>/dev/null |
    awk '$1 == 0 { print $2, $3 }' | sort -rn | head -1 | cut -d' ' -f2-
}

# _tmux_free_name — main, else main2, main3 … the first one not taken.
_tmux_free_name() {
  local n=main i=2
  while tmux has-session -t "=$n" 2>/dev/null; do
    n=main$i
    (( i++ ))
  done
  print -r -- "$n"
}

# _tmux_resume — attach to a free session, or start one. Used by both `t` with
# no argument and the auto-attach at the bottom.
_tmux_resume() {
  local free
  free=$(_tmux_free_session)
  if [[ -n $free ]]; then
    tmux attach -t "=$free"
  else
    tmux new-session -s "$(_tmux_free_name)"
  fi
}

# t — the only tmux command worth memorising.
#
#   t                attach to the session you were last in, or start `main`
#   t <name>         attach to <name>, creating it if it does not exist
#   t ls             what is running
#   t kill <name>    end one
#
# Already inside tmux, `t <name>` switches this client to another session rather
# than nesting a second server inside the first, which is never what you meant.
#
# The `=` in `-t "=$name"` is not decoration: without it tmux matches session
# names by prefix, so `t api` would happily attach you to `api-old`.
t() {
  case ${1:-} in
    ls | list)
      tmux list-sessions 2>/dev/null || print 'no sessions'
      return
      ;;
    kill)
      shift
      [[ -n ${1:-} ]] || { print -u2 'usage: t kill <name>'; return 1 }
      tmux kill-session -t "=$1"
      return
      ;;
  esac

  local name=${1:-}

  # No server running at all — the state after a reboot. Starting a server is
  # what triggers continuum's restore, but a server with no sessions exits
  # immediately, so the restore has to land beside one. Hence a placeholder,
  # dropped again once the saved sessions are back.
  #
  # The name is `__restore`, not `main`, because the saved state may well
  # contain a session called `main` — killing `=main` afterwards would then
  # destroy the restored one instead of the placeholder.
  if ! tmux has-session 2>/dev/null &&
     [[ -e ${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last ]]; then
    tmux new-session -d -s __restore 2>/dev/null
    local i
    for i in {1..24}; do          # continuum restores in the background
      (( $(tmux list-sessions 2>/dev/null | wc -l) > 1 )) && break
      sleep 0.25
    done
    (( $(tmux list-sessions 2>/dev/null | wc -l) > 1 )) &&
      tmux kill-session -t '=__restore' 2>/dev/null
  fi

  if [[ -n $TMUX ]]; then
    [[ -n $name ]] || {
      print -u2 't: already in a session. `t <name>` switches, Ctrl-b d detaches.'
      return 1
    }
    tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name"
    tmux switch-client -t "=$name"
    return
  fi

  if [[ -n $name ]]; then
    tmux new-session -A -s "$name"    # -A: attach if it exists, create if not
  else
    # Carry on where you left off — but only into a session nobody else is
    # already using. See _tmux_free_session.
    _tmux_resume
  fi
}

# _tmux_autoattach_wanted — should this shell drop straight into tmux?
#
# Only on machines reached over the network. Locally there are already iTerm2
# tabs and nothing that can drop the connection, so wrapping every shell in tmux
# would buy nothing and cost a keystroke prefix on all of them.
#
# Every guard below is a way this goes wrong in practice, which is why they are
# separate lines rather than one condition:
#
#   $TMUX          tmux runs $SHELL for every new pane. Without this, the first
#                  pane attaches to the session it is already in, forever.
#   $STY           the same trap, one multiplexer along (GNU screen).
#   interactive    `ssh host <cmd>`, scp, rsync and git-over-ssh all start a
#                  shell, and none of them may be handed a full-screen program.
#   -t 1           belt and braces for the same thing: no terminal, no tmux.
#   TERM=dumb      a captive shell inside an editor.
#   VS Code /      both reconnect their remote terminals themselves; tmux on
#   JetBrains      top of that confuses their session handling and yours.
#
# Kept as a function, not inlined, so that when a box does not auto-attach you
# can run it and read $? instead of guessing.
#
# DOTFILES_TMUX_AUTOATTACH=0 in ~/.zshrc.local turns it off for one machine.
_tmux_autoattach_wanted() {
  [[ ${DOTFILES_TMUX_AUTOATTACH:-1} == 1 ]] || return 1
  [[ -z $TMUX && -z $STY ]]                 || return 1
  [[ -o interactive ]]                      || return 1
  [[ -t 1 ]]                                || return 1
  [[ $TERM != dumb ]]                       || return 1
  [[ -z $VSCODE_INJECTION && $TERM_PROGRAM != vscode ]] || return 1
  [[ -z $TERMINAL_EMULATOR ]]               || return 1   # JetBrains sets this
  [[ -n $SSH_CONNECTION || -n $SSH_TTY || -n $SSH_CLIENT ||
     -n $CODER_AGENT_URL || -n $CODER_WORKSPACE_NAME ]]   || return 1
}

if _tmux_autoattach_wanted; then
  # Deliberately not `exec tmux`. exec replaces this shell, so a typo in
  # tmux.conf — or a missing terminfo entry — would end the ssh session the
  # instant tmux gave up, on the remote box, with no shell left to fix it from.
  # Run it normally and a failure just leaves you at a prompt. Detaching with
  # Ctrl-b d lands you at one too, which is also the friendlier ending.
  _tmux_resume
fi
