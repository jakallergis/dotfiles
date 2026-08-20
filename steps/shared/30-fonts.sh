# name: Fonts

case $OS in
  macos) dest="$HOME/Library/Fonts" ;;
  linux) dest="${XDG_DATA_HOME:-$HOME/.local/share}/fonts" ;;
  *) info "nothing to install on $OS"; return 0 ;;
esac

mkdir -p "$dest"
copied=0

while IFS= read -r font; do
  font_name=${font##*/}
  [ -f "$dest/$font_name" ] && continue
  cp "$font" "$dest/$font_name"
  copied=$((copied + 1))
done < <(find fonts -type f \( -name '*.ttf' -o -name '*.otf' \) 2>/dev/null)

if [ "$copied" = 0 ]; then
  info "all fonts already installed"
else
  ok "$copied font file(s) -> $dest"
  if [ "$OS" = linux ] && has fc-cache; then
    fc-cache -f >/dev/null
  fi
fi
