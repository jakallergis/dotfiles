# name: mise
#
# One version manager for everything, replacing nvm, bum, and the hand-rolled
# installers for atuin, zoxide, fzf, fd, bat, eza and delta. mise's installer is
# well behaved: it only *prints* the activation line, so
# `eval "$(mise activate zsh)"` lives in config/shared/.zshrc where it belongs.
#
# Both lists live here rather than in mise's ~/.config/mise/config.toml, so this
# step is the source of truth and a fresh machine gets the same set.

# Languages, where the version is the point. mise always owns these.
# ruby is built from source by ruby-build (core:ruby), so a fresh machine spends
# a few minutes here; node, bun and python come precompiled.
MANAGED="node@lts bun@latest python@3.12 ruby@3.4.7"

# Plain binaries. Skipped when one is already on PATH, so a brew or apt copy is
# left alone rather than quietly shadowed — uninstall the system copy and re-run
# if you would rather mise owned it. On my machines mise owns all of these.
TOOLS="fd bat eza delta fzf zoxide atuin"

PATH="$HOME/.local/bin:$PATH"

if has mise; then
  info "already installed ($(mise --version))"
else
  curl -fsSL https://mise.run | sh
  has mise || die "mise did not install"
  ok "mise $(mise --version)"
fi

# shellcheck disable=SC2086
mise use --global $MANAGED
ok "managed: $MANAGED"

for tool in $TOOLS; do
  if has "${tool%%@*}"; then
    info "${tool%%@*} already on PATH, leaving it alone"
  else
    mise use --global "$tool" && ok "$tool"
  fi
done

# mise reads .tool-versions and mise.toml out of the box but ignores the
# idiomatic files (.nvmrc, .python-version, .ruby-version, Gemfile):
# idiomatic_version_file_enable_tools defaults to an empty list, so existing
# projects would be silently ignored. config/shared/.zshrc exports the same
# setting for interactive shells; this covers mise run from an IDE or a script.
for _tool in node python ruby; do
  mise settings add idiomatic_version_file_enable_tools "$_tool" 2>/dev/null || true
done

# delta only does anything once git is told to use it. Idempotent.
if has delta; then
  git config --global core.pager delta
  git config --global interactive.diffFilter 'delta --color-only'
  git config --global delta.navigate true
  ok "git pages through delta"
fi

info "run 'mise doctor' if something looks off"
