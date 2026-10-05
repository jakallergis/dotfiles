# name: herdr integration
#
# herdr itself needs no step — it is in mise's registry as `aqua:herdrdev/herdr`
# and so is one tracked line in config/shared/.config/mise/config.toml, the same
# as tmux. mise's install paths come before ~/.local/bin on PATH, so a copy left
# behind by herdr's own installer is shadowed rather than fought with.
#
# What does need a step is the agent integration. `herdr integration install
# claude` writes ~/.claude/hooks/herdr-agent-state.sh, and that hook is the
# entire reason the sidebar can report idle/working/blocked/done: it fires on
# Claude Code's own hook events and writes to $HERDR_SOCKET_PATH for
# $HERDR_PANE_ID. Without it herdr sees panes but no agents.
#
# The hook is what makes a *remote* machine work too, because the socket has to
# be local to the agent — a Claude on a Coder box cannot report to a socket on
# the Mac. So this step matters most on exactly the machines you reach over ssh.
#
# Not done here, deliberately:
#   * `herdr machine add` — machine profiles are per-machine facts and must stay
#     out of the repo. They are also the only thing that makes cross-machine
#     control possible, so a profile appearing on a box is a decision, not a
#     default.
#   * the config — seeded by step 10 via COPY, because herdr writes config.toml
#     itself and has no include mechanism.

has herdr || { warn "herdr is not installed — run ./install.sh mise first"; return 0; }

ok "$(herdr --version 2>/dev/null | head -1)"

# Idempotent by inspection: `integration status` reports `current` once the
# installed hook matches the binary's bundled version, so a re-run is a no-op.
state=$(herdr integration status 2>/dev/null | LC_ALL=C grep -E '^claude:' || true)
case $state in
  *current*)
    ok "claude integration already current"
    ;;
  *)
    if herdr integration install claude >/dev/null 2>&1; then
      ok "installed the claude integration (agent state reporting)"
    else
      warn "could not install the claude integration — the sidebar will show panes but no agents"
      info "try by hand: herdr integration install claude"
    fi
    ;;
esac

live="$HOME/.config/herdr/config.toml"
tracked="$DOTFILES/config/shared/.config/herdr/config.toml"

if [ ! -f "$live" ]; then
  warn "no ~/.config/herdr/config.toml — run ./install.sh symlinks to seed it"
  return 0
fi

if herdr config check >/dev/null 2>&1; then
  ok "~/.config/herdr/config.toml validates"
else
  warn "herdr config has problems — run 'herdr config check' to see them"
fi

# Divergence has to be *reported*, because step 10 seeds this file only when it
# is absent and herdr's onboarding creates a one-line config on first launch.
# A machine that ever ran herdr before pulling these dotfiles therefore keeps
# that stub for ever and silently has none of the tracked keybindings — which is
# exactly what happened on the first Coder workspace: alt+g and alt+o did
# nothing there, and the file was `onboarding = false` and nothing else.
if [ -f "$tracked" ]; then
  if cmp -s "$tracked" "$live"; then
    ok "config matches the tracked baseline"
  elif [ "${DOTFILES_HERDR_ADOPT:-0}" = 1 ]; then
    mkdir -p "$HOME/.dotfiles-backup/.config/herdr"
    cp "$live" "$HOME/.dotfiles-backup/.config/herdr/config.toml"
    cp "$tracked" "$live"
    ok "adopted the tracked config (your old one is in ~/.dotfiles-backup/)"
    herdr server reload-config >/dev/null 2>&1 && info "reloaded the running server"
  else
    warn "this machine's herdr config differs from the tracked baseline"
    info "step 10 seeds it only when absent and never overwrites, so a machine that"
    info "launched herdr before pulling these dotfiles keeps its own stub."
    info "to adopt the tracked one (your current file is backed up first):"
    info "  DOTFILES_HERDR_ADOPT=1 ./install.sh herdr"
  fi
fi
