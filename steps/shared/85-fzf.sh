# name: fzf
#
# Wanted by zoxide's `zi` picker, and useful on its own for Ctrl-T and Alt-C.
# The shell wiring is a single `eval "$(fzf --zsh)"` in config/shared/.zshrc,
# which is also why the fallback below passes --bin: without it fzf's installer
# appends `source ~/.fzf.zsh` to ~/.zshrc, i.e. into this repo.

PATH="$HOME/.fzf/bin:$PATH"

if has fzf; then
  ok "already installed ($(fzf --version))"
  return 0
fi

if has brew; then
  brew install fzf
else
  # Distro packages lag badly — Ubuntu 22.04 ships 0.29, and `fzf --zsh` only
  # arrived in 0.48 — so take the binary from upstream instead.
  if [ -d "$HOME/.fzf/.git" ]; then
    git -C "$HOME/.fzf" pull --quiet --ff-only || warn "could not update ~/.fzf"
  else
    git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  fi
  "$HOME/.fzf/install" --bin
fi

has fzf || die "fzf did not install"
ok "$(fzf --version)"
