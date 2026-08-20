# name: nvm
#
# PROFILE=/dev/null is nvm's documented way to skip editing a shell profile.
# Ours already sources nvm, and ~/.zshrc is a symlink into this repo — an
# installer appending to it would be committing to git.

[ "$OS" = windows ] && { warn "nvm is unix-only — use WSL, or nvm-windows"; return 0; }

NODE_VERSION=--lts # or a major, e.g. 22

export NVM_DIR="$HOME/.nvm"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  info "nvm already installed"
else
  PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh)"
  [ -s "$NVM_DIR/nvm.sh" ] || die "nvm did not install"
  ok "nvm"
fi

# nvm is a shell function, not a binary, so it has to be sourced to be used.
# nvm.sh is not written to survive `set -u`.
set +u
. "$NVM_DIR/nvm.sh"
set -u

# Without a default, the load-nvmrc hook in .zshrc complains on every prompt.
if [ -f "$NVM_DIR/alias/default" ] && [ -n "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
  ok "default node is $(nvm version default)"
else
  nvm install "$NODE_VERSION"
  nvm alias default "$(nvm current)"
  ok "node $(nvm current) is the default"
fi
