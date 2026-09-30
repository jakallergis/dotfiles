# name: mise
#
# One version manager for node, bun, python, ruby and the CLI binaries. The tool
# list is not in this file: it lives in the tracked
# config/shared/.config/mise/config.toml, symlinked to ~/.config/mise by step 10.
# So `mise install` is the whole story, and `mise use -g <tool>` on any machine
# writes through that symlink into the repo, where it shows up as a diff to
# commit. (Verified: mise writes through the symlink rather than replacing it.)
#
# A fresh machine spends a few minutes here: ruby is built from source by
# ruby-build, while node, bun, python and the binaries come precompiled.

PATH="$HOME/.local/bin:$PATH"

if has mise; then
  info "already installed ($(mise --version))"
else
  curl -fsSL https://mise.run | sh
  has mise || die "mise did not install"
  ok "mise $(mise --version)"
fi

[ -f "$HOME/.config/mise/config.toml" ] || die "no mise config — run ./install.sh symlinks first"

mise install
ok "$(mise ls --global 2>/dev/null | wc -l | tr -d ' ') tools installed"

# delta is wired into git by the tracked shared.gitconfig, not here.

# conf.d is mise's own local overlay, and the escape hatch for a machine that
# needs a tool the repo should not carry. mise reads ~/.config/mise/conf.d/*.toml
# in addition to config.toml and merges the tools (verified). `mise use -g`
# still writes to the tracked config.toml, which is the point on your own
# machine — a new tool is a diff to commit. On a throwaway box, target the
# overlay instead and the repo stays clean:
#
#   mise use --path ~/.config/mise/conf.d/local.toml <tool>
mkdir -p "$HOME/.config/mise/conf.d"

info "run 'mise doctor' if something looks off"
