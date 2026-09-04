# name: Fonts
#
# Two sources, and the split is the point:
#
#   fonts/       files committed to this repo, copied as they are
#   MesloLGS NF  fetched from upstream, because it must not be committed
#
# MesloLGS NF is ~10MB across four weights — four times everything else in
# fonts/ put together. Committing it would put that in every clone forever,
# including the Coder workspaces that re-clone this repo on each create and have
# no display to render a font on. install.sh already needs the network for
# oh-my-zsh, p10k, mise and druk, so fetching costs a machine running this step
# nothing it does not already have.
#
# It is the font powerlevel10k is designed around: `POWERLEVEL9K_MODE` in
# config/shared/.p10k.zsh is set to nerdfont-v3, and lazygit's icons and
# `eza --icons` need it too. Point your terminal at "MesloLGS NF" afterwards —
# that part is the terminal's own preference file, not something this repo owns.

case $OS in
  macos) dest="$HOME/Library/Fonts" ;;
  linux) dest="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
  *) info "nothing to install on $OS"; return 0 ;;
esac

mkdir -p "$dest"
copied=0

# --- vendored -----------------------------------------------------------------
while IFS= read -r font; do
  font_name=${font##*/}
  [ -f "$dest/$font_name" ] && continue
  cp "$font" "$dest/$font_name"
  copied=$((copied + 1))
done < <(find fonts -type f \( -name '*.ttf' -o -name '*.otf' \) 2>/dev/null)

# --- MesloLGS NF, from upstream -----------------------------------------------
# romkatv publishes these alongside powerlevel10k itself, which is why they are
# taken from there rather than from the Nerd Fonts release: same four files the
# `p10k configure` wizard offers to install, so a machine set up either way ends
# up identical.
meslo_base="https://github.com/romkatv/powerlevel10k-media/raw/master"

if has curl; then
  for variant in Regular Bold Italic "Bold Italic"; do
    name="MesloLGS NF $variant.ttf"
    [ -f "$dest/$name" ] && continue

    # Download to a temp file and move it into place only on success. Writing
    # straight to $dest would leave a truncated font behind when the network
    # drops, and the `-f` test above would then skip it on every future run —
    # a broken font that repairs itself never.
    tmp=$(mktemp) || { warn "no mktemp — skipping $name"; continue; }
    if curl -fsSL -o "$tmp" "$meslo_base/${name// /%20}"; then
      mv "$tmp" "$dest/$name"
      copied=$((copied + 1))
    else
      rm -f "$tmp"
      warn "could not download $name — offline?"
    fi
  done
else
  warn "no curl, skipping MesloLGS NF"
fi

if [ "$copied" = 0 ]; then
  info "all fonts already installed"
else
  ok "$copied font file(s) -> $dest"
  if [ "$OS" = linux ] && has fc-cache; then
    fc-cache -f >/dev/null
  fi
fi

info 'set your terminal font to "MesloLGS NF" to see the icons'
