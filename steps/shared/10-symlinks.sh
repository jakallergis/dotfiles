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
#
# COPY names files that are *seeded* rather than linked, listed by their path
# under $HOME. The rule this repo now follows is "symlink only what nothing else
# writes"; where a tool rewrites its own config and offers no include or
# local-overlay file, a symlink can only mean a permanently dirty repo.
#
# Claude Code is that case: ~/.claude/settings.json is rewritten by the app and
# has no user-level settings.local.json to divert those writes to. So the repo
# copy is a starting point, copied once, and the machine owns it from then on.
# The tradeoff is real and one-directional: changes you make on a machine do not
# flow back, and have to be copied into the repo deliberately.
#
# herdr's config.toml is the same case for the same two reasons: it writes the
# file itself (`herdr config reset-keys`, the onboarding flag, and an atomic
# temp-file write), and it has no include mechanism — 210 config keys, none of
# which import another file.

MIRROR=".config .claude .agents"
COPY=".claude/settings.json .config/herdr/config.toml"

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

# copy_one <absolute source> <path relative to $HOME> — seed, never overwrite.
copy_one() {
  local src=$1 rel=$2 dest="$HOME/$2"

  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    info "$rel is machine-local already, left alone"
    return 0
  fi

  # Migration: this used to be a symlink into the repo.
  if [ -L "$dest" ]; then
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$dest" "$backup/$rel"
    warn "$rel was linked into the repo; the link moved to ~/.dotfiles-backup/"
  fi

  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  ok "$rel (seeded copy — this machine owns it now)"
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
          case " $COPY " in
            *" $rel "*) copy_one "$DOTFILES/$file" "$rel" ;;
            *)          link_one "$DOTFILES/$file" "$rel" ;;
          esac
        done < <(find "config/$lane/$name" -type f ! -name '.DS_Store')
        continue
        ;;
    esac

    link_one "$DOTFILES/$src" "$name"
  done
}

link_lane shared
link_lane "$OS"
