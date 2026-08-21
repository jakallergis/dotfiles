# name: Claude Code agents and commands
#
# ~/.claude/agents and ~/.claude/commands are checkouts of someone else's
# collections, not config — so they are cloned here rather than vendored into
# this repo, the same call as p10k and the zsh plugins. What IS tracked is
# ~/.claude/settings.json (which lists the enabled plugins declaratively).

has git || die "git is missing"

for spec in \
  "agents|https://github.com/wshobson/agents.git" \
  "commands|https://github.com/wshobson/commands.git"; do
  dir=${spec%%|*}
  url=${spec##*|}
  dest="$HOME/.claude/$dir"

  if [ -d "$dest/.git" ]; then
    info "$dir already cloned"
    if ! git -C "$dest" pull --quiet --ff-only 2>/dev/null; then
      # Name the culprit. An editor adding a trailing newline to one of these
      # files is enough to block every future update, and "could not update"
      # on its own sends you digging. Untracked additions (a symlink to your
      # own commands, say) are fine and are excluded here.
      dirty=$(git -C "$dest" status --porcelain --untracked-files=no | awk '{print $2}' | tr '\n' ' ')
      if [ -n "$dirty" ]; then
        warn "$dir not updated — your local changes to: $dirty"
        info "discard them with: git -C ~/.claude/$dir checkout -- ."
      else
        warn "$dir not updated — diverged from upstream, or offline"
      fi
    fi
  else
    mkdir -p "$HOME/.claude"
    git clone --quiet "$url" "$dest" && ok "$dir"
  fi
done
