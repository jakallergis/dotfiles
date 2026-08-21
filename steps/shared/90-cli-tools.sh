# name: CLI tools
#
# One step for four tools rather than four near-identical files: the install is
# the same for all of them and only the package name differs, so a table reads
# better than four copies.
#
#   fd     faster find; what fzf uses to list files
#   bat    cat with syntax highlighting; used for fzf previews
#   eza    ls with git status and a tree mode
#   delta  readable git diffs
#
# A tool missing from a distro's repos warns and is skipped rather than failing
# the run — eza in particular is not packaged before Debian 13 / Ubuntu 24.04.

PATH="$HOME/.local/bin:$PATH"

# apt renames two of these binaries to avoid clashing with older packages.
installed() {
  case $1 in
    fd) has fd || has fdfind ;;
    bat) has bat || has batcat ;;
    *) has "$1" ;;
  esac
}

# tool | brew | apt | dnf | pacman
TOOLS="
fd    | fd        | fd-find    | fd-find    | fd
bat   | bat       | bat        | bat        | bat
eza   | eza       | eza        | eza        | eza
delta | git-delta | git-delta  | git-delta  | git-delta
"

while IFS='|' read -r tool brew apt dnf pacman; do
  tool=$(printf '%s' "$tool" | tr -d ' ')
  [ -n "$tool" ] || continue

  if installed "$tool"; then
    info "$tool already installed"
    continue
  fi

  pkg=''
  if has brew; then pkg=$brew
  elif has apt-get; then pkg=$apt
  elif has dnf; then pkg=$dnf
  elif has pacman; then pkg=$pacman
  fi
  pkg=$(printf '%s' "$pkg" | tr -d ' ')

  if [ -z "$pkg" ]; then
    warn "$tool: no package manager I recognise, skipping"
    continue
  fi

  if has brew; then
    brew install "$pkg" || warn "$tool: brew could not install $pkg"
  elif has apt-get; then
    $SUDO apt-get install -y -qq "$pkg" || warn "$tool: not in this apt repo ($pkg)"
  elif has dnf; then
    $SUDO dnf install -y -q "$pkg" || warn "$tool: not in this dnf repo ($pkg)"
  elif has pacman; then
    $SUDO pacman -S --needed --noconfirm "$pkg" || warn "$tool: not in this pacman repo ($pkg)"
  fi

  installed "$tool" && ok "$tool" || warn "$tool: still missing"
done <<TABLE
$TOOLS
TABLE

# delta only does anything once git is told to use it. Idempotent.
if installed delta; then
  git config --global core.pager delta
  git config --global interactive.diffFilter 'delta --color-only'
  git config --global delta.navigate true
  ok "git configured to page through delta"
fi
