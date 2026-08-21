# name: Symlink dotfiles
#
# Everything in config/shared, plus everything in config/<os>, gets a symlink in
# $HOME under the same name. No list to maintain: add a file, get a link. A file
# in config/<os> replaces one with the same name in config/shared.
#
# MIRROR names the directories that other tools also write into — we descend
# into those and link individual files, so ~/.config, ~/.claude and ~/.agents
# stay real directories holding their own state. Everything else is linked as a
# whole, which is why adding a file to config/shared/.zshrc.d/ needs no re-run.

MIRROR=".config .claude .agents"

shopt -s dotglob nullglob

backup="$HOME/.dotfiles-backup"

# link_one <absolute source> <path relative to $HOME>
link_one() {
  local src=$1 rel=$2 dest="$HOME/$2"

  if [ "$(readlink "$dest" 2>/dev/null)" = "$src" ]; then
    info "$rel already linked"
    return 0
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$dest" "$backup/$rel"
    warn "your old $rel moved to ~/.dotfiles-backup/"
  fi

  mkdir -p "$(dirname "$dest")"
  # Git Bash needs developer mode for real symlinks; copy if it refuses.
  ln -s "$src" "$dest" 2>/dev/null || cp -R "$src" "$dest"
  ok "$rel"
}

link_lane() {
  local lane=$1 src name file rel
  for src in "config/$lane"/*; do
    name=${src##*/}

    if [ "$lane" = shared ] && [ -e "config/$OS/$name" ]; then
      info "$name comes from config/$OS instead"
      continue
    fi

    case " $MIRROR " in
      *" $name "*)
        while IFS= read -r file; do
          rel=${file#config/$lane/}
          link_one "$DOTFILES/$file" "$rel"
        done < <(find "config/$lane/$name" -type f ! -name '.DS_Store')
        continue
        ;;
    esac

    link_one "$DOTFILES/$src" "$name"
  done
}

link_lane shared
link_lane "$OS"
