# name: Xcode command line tools

if xcode-select -p >/dev/null 2>&1; then
  ok "already installed"
  return 0
fi

# Apple's installer draws its own window, so there is nothing to automate here.
[ -t 0 ] || die "run 'xcode-select --install' first"

xcode-select --install || true
info "finish Apple's installer window, then come back here"

until xcode-select -p >/dev/null 2>&1; do
  confirm "done installing?" || die "the command line tools are required"
done
ok "installed"
