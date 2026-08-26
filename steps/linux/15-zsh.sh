# name: Zsh

if has zsh; then
  ok "already installed ($(zsh --version))"
  return 0
fi

if [ "$CAN_ROOT" != 1 ]; then
  warn "no usable root — skipping. zsh is not in mise's registry, so it needs a"
  info "package manager: ask for sudo, or use an image that ships zsh"
  return 0
fi

if has apt-get; then
  $SUDO apt-get update -qq
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zsh
elif has dnf; then
  $SUDO dnf install -y -q zsh
elif has pacman; then
  $SUDO pacman -S --needed --noconfirm zsh
elif has apk; then
  $SUDO apk add --no-progress zsh
else
  die "no package manager I recognise — install zsh by hand"
fi

ok "$(zsh --version)"
