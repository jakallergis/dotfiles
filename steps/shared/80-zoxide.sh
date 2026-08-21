# name: zoxide
#
# A cd that learns where you go. Refreshingly, its installer writes no shell
# config at all — it only prints a note if the install dir is off PATH, and ours
# is not. The `zoxide init zsh` line lives in config/shared/.zshrc.

PATH="$HOME/.local/bin:$PATH"

if has zoxide; then
  ok "already installed ($(zoxide --version))"
  return 0
fi

# brew keeps it upgradable alongside everything else and is current (0.10.0);
# the official installer is the fallback, dropping a static binary in
# ~/.local/bin. Distro packages are skipped on purpose: Ubuntu 22.04 still
# ships 0.8, whose `zoxide init` output is not compatible.
if has brew; then
  brew install zoxide
else
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

has zoxide || die "zoxide did not install"
ok "$(zoxide --version)"

has fzf || info "install fzf if you want zoxide's interactive picker (zi)"
