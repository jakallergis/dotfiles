# name: Symlink dotfiles
#
# Everything in config/shared, plus everything in config/<os>, gets a symlink
# in $HOME under the same name. No list to maintain: add a file, get a link.
# A file in config/<os> replaces one with the same name in config/shared.

shopt -s dotglob nullglob

backup="$HOME/.dotfiles-backup"

link_lane() {
  local lane=$1 src name dest
  for src in "config/$lane"/*; do
    name=${src##*/}

    if [ "$lane" = shared ] && [ -e "config/$OS/$name" ]; then
      info "$name comes from config/$OS instead"
      continue
    fi

    dest="$HOME/$name"
    src="$DOTFILES/$src" # links must be absolute to survive a moved shell

    if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
      info "$name already linked"
      continue
    fi

    if [ -e "$dest" ] || [ -L "$dest" ]; then
      mkdir -p "$backup"
      mv "$dest" "$backup/$name"
      warn "your old $name moved to ~/.dotfiles-backup/"
    fi

    # Git Bash needs developer mode for real symlinks; copy if it refuses.
    ln -s "$src" "$dest" 2>/dev/null || cp -R "$src" "$dest"
    ok "$name"
  done
}

link_lane shared
link_lane "$OS"
