# name: powerlevel10k
#
# Installing belongs here; .zshrc only picks the theme,
# and falls back to the stock one if this step has not run.

omz=${ZSH:-$HOME/.oh-my-zsh}
[ -d "$omz" ] || { warn "oh-my-zsh is not installed yet, skipping"; return 0; }

dest="$omz/custom/themes/powerlevel10k"

if [ -d "$dest/.git" ]; then
  info "already installed"
  git -C "$dest" pull --quiet --ff-only || warn "could not update powerlevel10k"
else
  git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$dest"
  ok "powerlevel10k"
fi

if [ -d "$omz/custom/themes/powerlevel9k" ]; then
  warn "powerlevel9k is still in $omz/custom/themes — delete it once p10k sticks"
fi

if [ ! -f "$HOME/.p10k.zsh" ]; then
  info "p10k will offer to configure itself in your next shell"
  info "afterwards: mv ~/.p10k.zsh config/shared/ && ./install.sh symlinks"
fi
