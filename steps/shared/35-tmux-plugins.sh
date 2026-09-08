# name: tmux plugins
#
# What tmux cannot do on its own: survive the machine going away. A tmux server
# holds its sessions in memory, so a reboot — or a Coder workspace auto-stopping
# — takes every pane with it. resurrect writes the layout to disk; continuum
# does that on a timer and restores it when the server next starts.
#
# What comes back: sessions, windows, panes, their layout, and each pane's
# working directory. What does not: the processes. A dev server or a build is
# gone, by design — see @resurrect-processes in tmux.conf for the exceptions.
#
# **No TPM.** The tmux plugin manager is how these are usually installed, but
# both ship a standalone `.tmux` entrypoint, so `run-shell` in tmux.conf loads
# them directly. That is a whole dependency avoided for no loss — the same call
# as the zsh plugins in step 22, which are cloned rather than managed.
#
# Together they are ~1MB and 73 files with their own release history, which is
# what puts them over the "vendor it" line described in the README.

has git || die "git is missing"

# ~/.config/tmux is where tmux.conf already lives, and the symlink step only
# ever creates files inside it, so a plugins/ directory here is left alone.
#
# $HOME, not $XDG_CONFIG_HOME, deliberately: step 10 places tmux.conf with
# $HOME too, so this keeps the pair together. It also keeps the step testable —
# XDG_CONFIG_HOME is an absolute path, so `HOME=/tmp/fake ./install.sh` would
# otherwise clone straight into your real ~/.config, sandbox or not.
dest="$HOME/.config/tmux/plugins"
mkdir -p "$dest"

for repo in \
  https://github.com/tmux-plugins/tmux-resurrect \
  https://github.com/tmux-plugins/tmux-continuum; do
  name=${repo##*/}
  if [ -d "$dest/$name/.git" ]; then
    info "$name already installed"
    git -C "$dest/$name" pull --quiet --ff-only 2>/dev/null || warn "$name not updated"
  else
    git clone --depth 1 --quiet "$repo" "$dest/$name" && ok "$name"
  fi
done

info "saves land in $HOME/.local/share/tmux/resurrect"
