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
    # Bare `tmux attach` picks the most recently attached session — which is
    # exactly "carry on where I left off". Nothing there yet: start main.
    tmux attach 2>/dev/null || tmux new-session -s main
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
  tmux attach 2>/dev/null || tmux new-session -s main
fi
