#!/bin/sh
# ~/.config/tmux/claude-status.sh — symlinked from dotfiles/config/shared/
#
# Answers "which of my Claude sessions is waiting on me?" in one popup, and
# jumps to the pane you pick. Bound to Option-s in tmux.conf.
#
#   claude-status.sh --list             print the table and exit — also how it
#                                       is tested, since this needs no terminal
#   claude-status.sh --popup <client>   open the picker in a tmux popup
#   claude-status.sh --pick  <client>   the picker itself; runs inside the popup
#
# Why three modes rather than one: `display-popup -E` does **not** expand
# #{...} formats in its command, while `run-shell` does. So the key binding has
# to be a run-shell that expands #{client_name}, and that in turn opens the
# popup. Bind display-popup directly and the script receives the literal string
# "#{q:client_name}", tmux reports "can't find client", and the jump silently
# does nothing.
#
# How it knows: `claude agents --json` reports every running Claude with a pid
# and a status. Claude has no idea it is inside tmux, so the pid is joined to a
# tty through ps, and the tty to a pane through tmux. That chain is what makes
# jumping possible, and it is also why a Claude started outside tmux is listed
# but cannot be jumped to.
#
# `claude agents --json` is the load-bearing dependency and is not in
# `claude --help`'s documented surface, so treat it as liable to change: if the
# picker ever comes up empty, run that command by hand first.

set -u

self=$(cd "$(dirname "$0")" && pwd)/$(basename "$0")
mode=${1:---pick}
client=${2:-}

if [ "$mode" = "--popup" ]; then
  exec tmux display-popup -w 92% -h 85% -E "$self --pick '$client'"
fi

# Called by fzf for the highlighted row. It exists as a mode rather than an
# inline --preview string so the location can be printed above the pane
# contents: at a 25% split there is no room for a location column in the list,
# and knowing where Enter will take you still matters.
if [ "$mode" = "--preview" ]; then
  pane=${2:-}
  [ -n "$pane" ] || { echo "  (started outside tmux — nothing to preview, and nowhere to jump)"; exit 0; }
  loc=$(tmux display-message -p -t "$pane" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)
  [ -n "$loc" ] && printf '\033[36m%s\033[0m\n\n' "$loc"
  tmux capture-pane -ept "$pane" 2>/dev/null
  exit 0
fi

list_only=0
[ "$mode" = "--list" ] && list_only=1

command -v jq >/dev/null 2>&1 || { echo "claude-status: jq is not installed"; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "claude-status: claude is not installed"; exit 1; }

# BSD and GNU stat spell this differently and neither accepts the other's flag.
mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null || echo 0; }

# Claude buckets transcripts by directory, so the session id has to be found by
# glob rather than computed.
transcript_mtime() {
  for f in "${CLAUDE_CONFIG_DIR:-$HOME/.claude}"/projects/*/"$1".jsonl; do
    [ -f "$f" ] && { mtime "$f"; return; }
  done
  echo 0
}

agents=$(claude agents --json 2>/dev/null) || agents=''
rows=$(printf '%s' "$agents" |
  jq -r '.[] | select(.kind == "interactive") | [.pid, .status, .sessionId, .cwd, .name] | @tsv' 2>/dev/null)

if [ -z "$rows" ]; then
  echo "No Claude sessions running."
  [ "$list_only" = 1 ] || { printf 'Press any key…'; read -r _ ; }
  exit 0
fi

seen=$(printf '%s\n' "$rows" | cut -f3 | while IFS= read -r sid; do
  printf 'M\t%s\t%s\n' "$sid" "$(transcript_mtime "$sid")"
done)

# Side by side, because a pane's contents are tall: giving the preview the full
# height of the popup shows far more of the conversation than a strip along the
# bottom. Below ~120 columns there is no room for two panes, so it stacks.
#
# The width test is done here rather than with fzf's own `<120(down,55%)`
# alternative-layout syntax, which did not behave as documented on 0.74.3 —
# it forced the alternative even in a 163-column popup. An explicit branch is
# one line longer and actually predictable.
#
# `stty size`, and not the obvious alternatives, because inside display-popup
# only stty tells the truth. Measured in a 154-column popup on a 170-column
# client: tput cols said 80 (the terminfo default — it never sees the popup),
# $COLUMNS was unset, and #{client_width} said 170, which is the client behind
# the popup rather than the popup itself.
cols=$(stty size 2>/dev/null | awk '{print $2}')
[ -n "${cols:-}" ] || cols=120

# 25/75. The list carries little information and the preview carries a whole
# conversation, so the split is lopsided on purpose.
#
# list_w is what the rows actually get to paint on: a quarter of the popup,
# less fzf's two-column pointer gutter and the one-column border. The columns
# below are then sized from it, rather than padded to a constant — a fixed-width
# row leaves dead space in a wide split and gets ellipsised in a narrow one, and
# both were visible before this.
if [ "$list_only" = 1 ]; then
  list_w=$(( cols - 2 ))          # printing to a shell: use the whole terminal
elif [ "$cols" -ge 120 ]; then
  preview_window='right,75%,follow,border-left'
  list_w=$(( cols / 4 - 3 ))
else
  preview_window='down,55%,follow,border-top'
  list_w=$(( cols - 3 ))
fi

# --- Claude on the far side of an ssh -----------------------------------------
# `claude agents --json` only knows about local processes, so a pane ssh'd into
# another machine contributes nothing — even though the Claude over there is
# painting its interface onto a pane tmux already holds locally. Reading that
# costs nothing: no network, no auth, no latency, and it works identically for
# `docker exec` or anything else that fills a pane from somewhere unaskable.
#
# The trade is that the status is inferred from what is on screen, so it is
# marked with a `?` and cannot separate "waiting for you" from "finished its
# turn". Measured against known panes: a busy Claude prints "esc to interrupt",
# an idle one does not, and both carry the footer matched below.
#
# Only panes with no local Claude on their tty are scanned, so nothing is
# listed twice and the usual case does no extra work.
claude_ttys=$(printf '%s\n' "$rows" | cut -f1 | while IFS= read -r apid; do
  ps -o tty= -p "$apid" 2>/dev/null | tr -d ' '
done)

scraped=$(tmux list-panes -a \
    -F '#{pane_id}	#{pane_tty}	#{session_name}:#{window_index}.#{pane_index}	#{pane_current_command}	#{pane_pid}' 2>/dev/null |
  while IFS='	' read -r sp_id sp_tty sp_loc sp_cmd sp_pid; do
    short=${sp_tty#/dev/}
    printf '%s\n' "$claude_ttys" | grep -qxF "$short" && continue

    screen=$(tmux capture-pane -pt "$sp_id" 2>/dev/null | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
    # Claude's footer reads "? for shortcuts", or the auto-mode line instead
    # when auto mode is on. Matching either covers both.
    printf '%s' "$screen" | grep -qE 'for shortcuts|auto mode on' || continue

    if printf '%s' "$screen" | grep -q 'esc to interrupt'; then sp_st=busy; else sp_st=idle; fi

    sp_label=$sp_cmd
    # The leading ( on the pattern is load-bearing, not decoration. This case
    # sits inside $( ... ), and the pattern's closing ) is otherwise read as
    # the end of the command substitution — the parser then reports a syntax
    # error at the ;; several lines later, nowhere near the actual cause.
    case $sp_cmd in
      (ssh | mosh)
        # First non-option word that is not the argument of one, which is the
        # destination for `ssh -l giannis ai-workstation` and friends.
        host=$(ps -Ao ppid=,command= | awk -v pp="$sp_pid" '$1==pp {
          for (i = 3; i <= NF; i++) {
            if ($i == "-l" || $i == "-p" || $i == "-i" || $i == "-o" || $i == "-F") { i++; continue }
            if (substr($i, 1, 1) != "-") { print $i; exit }
          }
        }')
        [ -n "$host" ] && sp_label="$sp_cmd $host"
        ;;
    esac
    printf 'S\t%s\t%s\t%s\t%s\n' "$sp_id" "$sp_loc" "$sp_st" "$sp_label"
  done)

table=$({
  ps -Ao pid=,tty= 2>/dev/null | awk '{ print "P\t" $1 "\t" $2 }'
  tmux list-panes -a -F 'T	#{pane_tty}	#{pane_id}	#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null
  printf '%s\n' "$seen"
  printf '%s\n' "$rows" | sed 's/^/A\t/'
  printf '%s\n' "$scraped"
} | awk -F'\t' -v now="$(date +%s)" -v home="$HOME" -v w="$list_w" '
  # Columns sized to fill w exactly. Fixed part: dot+space, status+space,
  # space+age. Whatever is left goes to the name, and to the tmux location too
  # once there is enough room for it to be worth showing.
  function emit(rank, dot, word, where, name, age, id,    fixed, show_loc, loc_w, name_w) {
    fixed = 2 + 8 + 4
    show_loc = (w - fixed >= 38)
    loc_w  = show_loc ? 18 : 0
    name_w = w - fixed - (show_loc ? loc_w + 1 : 0)
    if (name_w < 8) name_w = 8
    # Plain ".." rather than an ellipsis: the padding counts bytes, so a
    # multi-byte character in the marker knocks the column out of alignment.
    if (length(name) > name_w) name = substr(name, 1, name_w - 2) ".."
    if (show_loc && length(where) > loc_w) where = substr(where, 1, loc_w - 2) ".."
    if (show_loc)
      printf "%d\t%s %-7s \033[36m%-*s\033[0m %-*s \033[90m%3s\033[0m\t%s\n", rank, dot, word, loc_w, where, name_w, name, age, id
    else
      printf "%d\t%s %-7s %-*s \033[90m%3s\033[0m\t%s\n", rank, dot, word, name_w, name, age, id
  }
  $1 == "P" { tty_of[$2] = $3; next }
  $1 == "T" { sub(/^\/dev\//, "", $2); pane[$2] = $3; loc[$2] = $4; next }
  $1 == "M" { seen_at[$2] = $3; next }
  # Inferred from the screen, so the word carries a ? and there is no age.
  $1 == "S" {
    if ($4 == "busy") emit(3, "\033[31m●\033[0m", "busy?", $3, $5, "-", $2)
    else              emit(1, "\033[32m●\033[0m", "idle?", $3, $5, "-", $2)
    next
  }
  $1 == "A" {
    pid = $2; status = $3; sid = $4; dir = $5; name = $6
    tty = tty_of[pid]
    # Sorted by who needs you, not alphabetically: waiting first, busy last.
    # `status` is genuinely null sometimes — jq renders that as an empty field,
    # which printed a dot with no word next to it until it was handled here.
    if      (status == "waiting") { dot = "\033[33m●\033[0m"; word = "waiting"; rank = 0 }
    else if (status == "idle")    { dot = "\033[32m●\033[0m"; word = "idle";    rank = 1 }
    else if (status == "busy")    { dot = "\033[31m●\033[0m"; word = "busy";    rank = 3 }
    else if (status == "")        { dot = "\033[90m●\033[0m"; word = "?";       rank = 2 }
    else                          { dot = "\033[90m●\033[0m"; word = status;    rank = 2 }
    age = (seen_at[sid] > 0) ? int((now - seen_at[sid]) / 60) "m" : "-"
    where = (tty != "" && (tty in pane)) ? loc[tty] : "not in tmux"
    id    = (tty != "" && (tty in pane)) ? pane[tty] : ""
    # The name Claude gives a session beats the path here: the tmux location
    # already names the project, and several panes in one directory are
    # indistinguishable by path and obvious by name.
    if (name == "") { sub("^" home, "~", dir); name = dir }
    emit(rank, dot, word, where, name, age, id)
  }
' | sort -n | cut -f2-)

if [ "$list_only" = 1 ]; then
  printf '%s\n' "$table" | cut -f1
  exit 0
fi

# --height and --border are overridden on purpose. $FZF_DEFAULT_OPTS carries
# `--height 60% --border` for inline use in a shell, where both are right; in a
# popup they leave 40% of the box empty below the preview and draw a second
# border inside the popup's own. fzf applies the env var before these flags, so
# stating them here wins.
#
sel=$(printf '%s\n' "$table" | fzf --ansi --delimiter='\t' --with-nth=1 \
  --height=100% --border=none --info=inline --layout=reverse \
  --header='enter: jump to it   ctrl-c: cancel' \
  --preview="$self --preview {2}" \
  --preview-window="$preview_window") || exit 0

pane=$(printf '%s' "$sel" | cut -f2)
[ -n "$pane" ] || exit 0

# switch-client needs -c: inside display-popup the "current" client is the popup
# itself, so without it the jump lands nowhere the user can see.
session=$(tmux display-message -p -t "$pane" '#{session_name}' 2>/dev/null)
if [ -n "$client" ]; then
  tmux switch-client -c "$client" -t "$session" 2>/dev/null
else
  tmux switch-client -t "$session" 2>/dev/null
fi
tmux select-window -t "$pane" 2>/dev/null
tmux select-pane -t "$pane" 2>/dev/null
