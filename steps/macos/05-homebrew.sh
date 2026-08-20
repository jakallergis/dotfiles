# name: Homebrew
#
# The PATH/shellenv line lives in config/shared/.zshrc, not here: no step
# should be appending to your shell profile.

if has brew; then
  ok "already installed"
  return 0
fi

NONINTERACTIVE=1 /bin/bash -c \
  "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ok "installed"
