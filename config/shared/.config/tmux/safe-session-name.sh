#!/bin/sh
# Keep `.` and `:` out of session names, because a tmux target is not a string.
#
# A target is parsed as `session:window.pane` *before* any name is matched, so a
# session called `[ARI-46873] - Remove logger.notify` cannot be addressed as
# `<name>:1` by anything. Tested: no escaping helps — not `\.`, not the `=`
# exact-match prefix, nothing. Session IDs are the only safe target, and code
# that builds `"$name:$window"` is therefore simply broken for these names.
#
# Our own `t` was fixed by resolving names to IDs (see .zshrc.d/tmux.zsh), but
# tmux-resurrect has the identical bug in about twenty places and upstream has
# not fixed it. A real restore lost two panes and one working directory,
# reporting `can't find pane: notify` and `can't find window:  request
# aborted:1`. Patching a cloned third-party plugin would be wiped by its next
# pull, so the problem is removed at the source instead: the characters never
# get into a name.
#
# The replacements are homoglyphs, so the name looks unchanged:
#
#   .  ->  U+2024 ONE DOT LEADER
#   :  ->  U+2236 RATIO
#
# Verified that `session:window` targets, `split-window` and a full resurrect
# save/restore all work with these, and fail with the originals. The trade is
# that a name typed with real `.`/`:` will not match any more — `t "[ARI-46803]
# - BadRequestError: request aborted"` finds nothing — so reach for the
# Option-s picker, which is how these get selected anyway.
#
# Takes no arguments on purpose. Passing `#{hook_session_name}` through
# `run-shell` would mean quoting a name containing arbitrary characters through
# two parsers, which is the class of bug being fixed. Instead it sweeps every
# session, which also makes it idempotent and lets one call clean up sessions
# that already exist.
#
# Renaming fires session-renamed and so re-enters this script. That terminates:
# the new name contains neither character, the `case` below skips it, and no
# rename happens. One extra no-op pass, no loop.

command -v tmux >/dev/null 2>&1 || exit 0

tmux list-sessions -F '#{session_id}	#{session_name}' 2>/dev/null |
while IFS='	' read -r id name; do
  case $name in
    *.* | *:*) ;;
    *) continue ;;
  esac

  # LC_ALL=C so sed works on bytes. Under a UTF-8 locale it can refuse a name
  # that already holds multibyte characters with "RE error: illegal byte
  # sequence" — and these names do, the moment this script has run once.
  safe=$(printf '%s' "$name" | LC_ALL=C sed 's/\./․/g; s/:/∶/g')

  [ -n "$safe" ] || continue
  [ "$safe" = "$name" ] && continue

  tmux rename-session -t "$id" "$safe"
done

exit 0
