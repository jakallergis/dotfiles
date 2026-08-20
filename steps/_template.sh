# name: What this does
#
# Copy me to steps/shared/<NN>-<slug>.sh, or steps/macos|linux|windows/ if it
# only applies there. NN decides the order across both folders. Files starting
# with "_" are ignored.
#
# install.sh gives you: $OS (macos|linux|windows), $DOTFILES (this repo),
# has <cmd>, info/ok/warn/err <text>, die <text>, confirm "q?", ask "q?" "default".
# Use `return 0` to bail out early — and make sure the last line succeeds,
# because a false one fails the step.

has example || die "install example first"

if [ -f "$HOME/.example" ]; then
  ok "already configured"
  return 0
fi

echo "hello" > "$HOME/.example"
ok "configured"
