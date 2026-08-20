# name: atuin
#
# Straight to the release installer: setup.atuin.sh adds nothing but a banner
# and appends to .zshrc/.bashrc. ATUIN_NO_MODIFY_PATH stops this one doing the
# same — config/shared/.zshrc already sources atuin and calls `atuin init zsh`.

[ "$OS" = windows ] && { warn "atuin's installer is unix-only — use WSL"; return 0; }

atuin_bin="$HOME/.atuin/bin/atuin"

if has atuin || [ -x "$atuin_bin" ]; then
  ok "already installed ($(atuin --version 2>/dev/null || "$atuin_bin" --version))"
  return 0
fi

curl --proto '=https' --tlsv1.2 -LsSf \
  https://github.com/atuinsh/atuin/releases/latest/download/atuin-installer.sh |
  ATUIN_NO_MODIFY_PATH=1 sh

[ -x "$atuin_bin" ] || die "atuin did not install"
ok "$("$atuin_bin" --version)"
info "run 'atuin login' if you want history sync on this machine"
