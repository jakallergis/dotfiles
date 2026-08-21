# name: zsh plugins
#
# The two that oh-my-zsh does not bundle. .zshrc only adds a plugin to its list
# when the directory exists, so skipping this step is harmless.

omz=${ZSH:-$HOME/.oh-my-zsh}
[ -d "$omz" ] || { warn "oh-my-zsh is not installed yet, skipping"; return 0; }

for repo in \
  https://github.com/zsh-users/zsh-autosuggestions \
  https://github.com/zsh-users/zsh-syntax-highlighting; do
  name=${repo##*/}
  dest="$omz/custom/plugins/$name"
  if [ -d "$dest/.git" ]; then
    info "$name already installed"
  else
    git clone --depth 1 "$repo" "$dest"
    ok "$name"
  fi
done
