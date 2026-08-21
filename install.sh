#!/usr/bin/env bash
#
# Runs every script in steps/shared and steps/<os>, merged together and
# ordered by the number each filename starts with. That's the whole design:
# to add something, drop a numbered .sh file in one of those folders.
#
#   ./install.sh                 ask before each step
#   ./install.sh -y              run everything without asking
#   ./install.sh -n              show what would run
#   ./install.sh zsh fonts       run only steps matching these words
#
# Not cloned yet? This same script bootstraps itself:
#
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/jakallergis/dotfiles/master/install.sh)"
#
# To pass flags that way, give $0 a placeholder first, as omz does:
#
#   sh -c "$(curl -fsSL .../install.sh)" "" -y

# --- bootstrap ---------------------------------------------------------------
# Two cases, one block, and both must be handled in POSIX sh before the bash
# features below are reached:
#
#   piped from curl   there is no checkout and "$0" is not a file
#   run under sh      the shebang is ignored, so bash features would break
DOTFILES_REPO=${DOTFILES_REPO:-https://github.com/jakallergis/dotfiles}
DOTFILES_DIR=${DOTFILES_DIR:-$HOME/.dotfiles}

if [ ! -f "$0" ] || [ ! -d "$(dirname "$0")/steps" ]; then
  command -v git >/dev/null 2>&1 || { echo "install.sh: git is required to clone the repo" >&2; exit 1; }
  command -v bash >/dev/null 2>&1 || { echo "install.sh: bash is required" >&2; exit 1; }

  if [ -d "$DOTFILES_DIR/.git" ]; then
    echo "dotfiles already at $DOTFILES_DIR — pulling"
    git -C "$DOTFILES_DIR" pull --ff-only || true
  else
    echo "Cloning $DOTFILES_REPO into $DOTFILES_DIR"
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || exit 1
  fi
  exec bash "$DOTFILES_DIR/install.sh" "$@"
elif [ -z "${BASH_VERSION:-}" ]; then
  exec bash "$0" "$@"
fi

set -euo pipefail
cd "$(dirname "$0")"
DOTFILES=$(pwd)

# --- looks ------------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  bold=$'\033[1m' dim=$'\033[2m' red=$'\033[31m' green=$'\033[32m'
  yellow=$'\033[33m' blue=$'\033[36m' reset=$'\033[0m'
else
  bold='' dim='' red='' green='' yellow='' blue='' reset=''
fi

title() { printf '\n%s==> %s%s\n' "$bold" "$*" "$reset"; }
info()  { printf '    %s\n' "$*"; }
ok()    { printf '    %s+%s %s\n' "$green" "$reset" "$*"; }
warn()  { printf '    %s!%s %s\n' "$yellow" "$reset" "$*"; }
err()   { printf '    %sx%s %s\n' "$red" "$reset" "$*" >&2; }
die()   { err "$*"; exit 1; }
has()   { command -v "$1" >/dev/null 2>&1; }

# Steps that need root write "$SUDO apt-get …": empty when we already are root,
# or when there is no sudo at all (containers) and the command has to try anyway.
if [ "$(id -u)" = 0 ] || ! has sudo; then SUDO=''; else SUDO=sudo; fi

# confirm "question" — yes unless the user says otherwise. Always yes with -y
# or when there is nobody at the keyboard.
confirm() {
  [ "$ASSUME_YES" = 1 ] && return 0
  [ -t 0 ] || return 0
  local reply
  printf '    %s?%s %s [Y/n] ' "$blue" "$reset" "$*"
  read -r reply || reply=''
  case $reply in [Nn]*) return 1 ;; *) return 0 ;; esac
}

# ask "question" "default" — echoes the answer, or the default when unattended.
ask() {
  local reply
  if [ "$ASSUME_YES" = 1 ] || [ ! -t 0 ]; then printf '%s' "$2"; return 0; fi
  printf '    %s?%s %s %s[%s]%s ' "$blue" "$reset" "$1" "$dim" "$2" "$reset" >&2
  read -r reply || reply=''
  printf '%s' "${reply:-$2}"
}

banner() {
  printf '%s' "$yellow"
  cat <<'ART'

          _ ._  _ , _ ._
        (_ ' ( `  )_  .__)
      ( (  (    )   `)  ) _)
     (__ (_   (_ . _) _) ,__)
           ~~\ ' . /~~
         ,::: ;   ; :::,
        ':::::::::::::::'
ART
  printf '%s\n  %sdotfiles%s %s· jakallergis%s\n' "$reset" "$bold" "$reset" "$dim" "$reset"
}

# --- where are we -----------------------------------------------------------

# DOTFILES_OS=linux ./install.sh -n  shows another machine's plan from here.
# (Not $OS: cmd.exe sets OS=Windows_NT and Git Bash inherits it.)
OS=${DOTFILES_OS:-}
if [ -z "$OS" ]; then
  case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux) OS=linux ;;
    MINGW* | MSYS* | CYGWIN*) OS=windows ;;
    *) die "unsupported system: $(uname -s)" ;;
  esac
fi

# add homebrew to PATH on macOS, so steps can use it without installing it first
if [ "$OS" = macos ]; then
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
fi

# --- arguments --------------------------------------------------------------

ASSUME_YES=0 DRY_RUN=0 ONLY=''
while [ $# -gt 0 ]; do
  case $1 in
    -y | --yes) ASSUME_YES=1 ;;
    -n | --dry-run) DRY_RUN=1 ;;
    -h | --help) awk 'NR>1 && /^#/ { sub(/^# ?/, ""); print; next } NR>1 { exit }' "$0"; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) ONLY="$ONLY $1" ;;
  esac
  shift
done

# --- which steps ------------------------------------------------------------

# Both folders in one list, sorted by filename, so shared/20-zsh.sh runs
# between macos/05-homebrew.sh and macos/50-defaults.sh. A file in the OS
# folder replaces a shared one with the same name.
steps() {
  local dir file name
  for dir in steps/shared "steps/$OS"; do
    [ -d "$dir" ] || continue
    for file in "$dir"/*.sh; do
      [ -f "$file" ] || continue
      name=${file##*/}
      case $name in _* | .*) continue ;; esac
      [ "$dir" = steps/shared ] && [ -f "steps/$OS/$name" ] && continue
      printf '%s\n' "$file"
    done
  done | sort -t/ -k3
}

# The "# name:" comment on line 1, or the filename if there isn't one.
step_name() {
  local name
  name=$(sed -n 's/^# *name: *//p' "$1" | head -1)
  [ -n "$name" ] && printf '%s' "$name" || printf '%s' "$(basename "$1" .sh)"
}

wanted() {
  local word
  [ -z "$ONLY" ] && return 0
  for word in $ONLY; do
    case $1 in *"$word"*) return 0 ;; esac
  done
  return 1
}

# --- go ---------------------------------------------------------------------

banner
info "${dim}system${reset}  $OS ($(uname -m))"
info "${dim}repo${reset}    $DOTFILES"
[ "$DRY_RUN" = 1 ] && info "${dim}mode${reset}    dry run, nothing will change"

ran=0
for step in $(steps); do
  wanted "$step" || continue
  name=$(step_name "$step")

  if [ "$DRY_RUN" = 1 ]; then
    title "$name"
    info "${dim}$step${reset}"
    continue
  fi

  title "$name"
  confirm "run this step?" || { info "${dim}skipped${reset}"; continue; }

  # A subshell, so a step cannot cd or exit its way out of the installer. It
  # has to be a standalone command: bash suspends errexit inside an `if`
  # condition, and a step would then carry on after a failed command.
  set +e
  ( set -e; . "$step" )
  status=$?
  set -e
  [ "$status" = 0 ] || die "step failed  (re-run just this one: ./install.sh $(basename "$step" .sh))"
  ran=$((ran + 1))
done

[ "$DRY_RUN" = 1 ] && exit 0

title "Done"
ok "$ran step(s) completed"

# Land the user in zsh if they are not there already: on machines where the
# login shell could not be changed, this is what makes the change visible now.
if [ -t 1 ] && [ -z "${ZSH_VERSION:-}" ] && has zsh && [ "$OS" != windows ]; then
  if confirm "switch this shell to zsh?"; then
    info "${dim}exec zsh -l${reset}"
    SHELL=$(command -v zsh)
    export SHELL
    exec "$SHELL" -l
  fi
fi
