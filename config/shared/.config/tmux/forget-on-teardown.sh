#!/bin/sh
# ~/.config/tmux/forget-on-teardown.sh — symlinked from dotfiles/config/shared/
#
# Run from the `session-closed` hook in tmux.conf. Its whole job is to tell two
# situations apart that look identical from the outside once the server is gone:
#
#   the machine restarted   → sessions were taken away, bring them back
#   I typed `exit` in the   → sessions were dismissed on purpose, leave them
#   last pane                 dismissed
#
# The saved state is what continuum restores from, so a deliberate teardown has
# to remove it or the next `t` faithfully rebuilds the panes you just closed.
#
# Renamed rather than deleted: `last` is a symlink and the timestamped state
# file it points at is untouched, so `mv last.closed last` inside the resurrect
# directory undoes this if you close everything by mistake.

# Not the last session — other sessions are still live, so their layout is
# still worth keeping.
[ -n "$(tmux list-sessions 2>/dev/null)" ] && exit 0

# Ask tmux where resurrect is actually saving rather than assuming, and fall
# back the same way resurrect itself does — it prefers a pre-existing
# ~/.tmux/resurrect over the XDG path.
dir="$(tmux show-options -gqv @resurrect-dir 2>/dev/null)"
if [ -z "$dir" ]; then
  if [ -d "$HOME/.tmux/resurrect" ]; then
    dir="$HOME/.tmux/resurrect"
  else
    dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
  fi
fi
[ -e "$dir/last" ] || exit 0
mv -f "$dir/last" "$dir/last.closed" 2>/dev/null || rm -f "$dir/last"

# tmux.conf turns exit-empty off purely so this hook gets a chance to run at
# all. Now that it has, an empty server has nothing left to do, so shut it down
# the way the default would have — otherwise it lingers until the next reboot.
tmux kill-server 2>/dev/null

exit 0
