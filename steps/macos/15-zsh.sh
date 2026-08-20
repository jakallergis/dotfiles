# name: Zsh
#
# macOS has shipped zsh at /bin/zsh since Catalina, so there is normally
# nothing to do. Homebrew's zsh is only worth it if you need a newer one than
# Apple ships — swap the line below for `brew install zsh` if that day comes.

if has zsh; then
  ok "already installed ($(zsh --version))"
  return 0
fi

# Only reachable on something very old, or with a broken PATH.
has brew || die "no zsh and no Homebrew — run the Homebrew step first"
brew install zsh
ok "$(zsh --version)"
