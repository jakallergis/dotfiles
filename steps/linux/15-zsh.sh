# name: Zsh

if has zsh; then
  ok "already installed ($(zsh --version))"
  return 0
fi

if [ -z "$SUDO" ] && [ "$(id -u)" != 0 ]; then
  warn "no root here — install zsh by hand, then re-run"
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
