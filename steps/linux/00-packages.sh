# name: Base packages
#
# Only what is needed for the rest of the steps to work — zsh has its own step.
# Add your distro here if you meet one that is missing.

packages="git curl unzip vim tmux"

if [ -z "$SUDO" ] && [ "$(id -u)" != 0 ]; then
  warn "no root here — install by hand: $packages"
  return 0
fi

if has apt-get; then
  $SUDO apt-get update -qq
  # shellcheck disable=SC2086
  $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $packages
elif has dnf; then
  # shellcheck disable=SC2086
  $SUDO dnf install -y -q $packages
elif has pacman; then
  # shellcheck disable=SC2086
  $SUDO pacman -S --needed --noconfirm $packages
else
  die "no package manager I recognise — install by hand: $packages"
fi

ok "$packages"
