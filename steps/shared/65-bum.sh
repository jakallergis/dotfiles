# name: bum + bun
#
# bum is a version manager for bun, so bun comes from bum rather than from its
# own installer. Two things about bum's install.sh are worth knowing:
#
#   * when bun is missing it runs bun's installer, and that one appends its
#     PATH lines to ~/.zshrc every run with no check for what is already
#     there. SHELL=none puts both installers in their "print the instructions"
#     branch; the exports live in config/shared/.zshrc instead.
#   * it untars into the current directory, so this runs it from a temp dir —
#     otherwise it extracts bum-v0.7.22-<target>/ into this checkout.

[ "$OS" = windows ] && { warn "bum is unix-only — use WSL"; return 0; }

export BUM_INSTALL="$HOME/.bum"
PATH="$BUM_INSTALL/bin:$HOME/.bun/bin:$PATH"

if has bum; then
  info "bum already installed"
else
  (cd "$(mktemp -d)" && SHELL=none bash -c "$(curl -fsSL https://github.com/owenizedd/bum/raw/main/install.sh)")
  has bum || die "bum did not install"
  ok "bum"
fi

# Always the newest bun, and installed *through* bum. bum's installer gets bun
# from bun's own installer, which leaves `bum list` empty and bum managing
# nothing — so the check below is against bum's registry, not `bun --version`.
# bum has no `default` command yet (its README lists it as a future feature),
# so the version is resolved here and handed to `bum use`.
latest=$(curl -fsSL https://api.github.com/repos/oven-sh/bun/releases/latest |
  sed -n 's/.*"tag_name": *"bun-v\([^"]*\)".*/\1/p' | head -1)
[ -n "$latest" ] || die "could not work out the latest bun version"

if [ -d "$BUM_INSTALL/bun-versions/$latest" ]; then
  ok "bun $latest already managed by bum"
else
  bum use "$latest"
  ok "bun $(bun --version) via bum"
fi
