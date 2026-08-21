# name: Git (latest)
#
# The folklore is that a Mac ships an ancient git and you must install a newer
# one. Both directions actually happen:
#
#   * Apple's git under /usr/bin can lag behind upstream, and
#   * a brew git installed once and never upgraded ends up shadowing a *newer*
#     Apple one, because brew's bin comes first on PATH.
#
# So this installs or upgrades brew's git and then checks which one really wins.
#
# The step people half-remember — replacing /usr/bin/git — is not possible on a
# modern Mac: SIP protects /usr/bin. PATH order is the whole mechanism, and
# `brew shellenv` (section 2 of .zshrc) is what provides it.

has brew || die "Homebrew first — run ./install.sh homebrew"

if brew list --formula git >/dev/null 2>&1; then
  brew upgrade git 2>/dev/null || info "brew's git is already current"
else
  brew install git
fi

version_of() { "$1" --version 2>/dev/null | awk '{print $3}'; }

# newer <a> <b> — true when version a is greater than b
newer() {
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ]
}

front=$(command -v git)
front_v=$(version_of "$front")
apple_v=$(version_of /usr/bin/git)

ok "git $front_v from $front"

if [ -n "$apple_v" ] && newer "$apple_v" "$front_v"; then
  warn "Apple's /usr/bin/git is $apple_v — newer than the $front_v in front of it"
  info "brew's copy is stale: run 'brew upgrade git', or drop brew's git with 'brew uninstall git'"
elif [ -n "$apple_v" ]; then
  info "Apple's /usr/bin/git is $apple_v, shadowed as intended"
fi
