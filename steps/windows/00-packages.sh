# name: Base packages
#
# Runs inside Git Bash. WSL is the nicer place to work; this is for when you
# are on the Windows side anyway.

has winget || die 'no winget — install "App Installer" from the Microsoft Store'

for id in Git.Git BurntSushi.ripgrep.MSVC jqlang.jq; do
  winget list --id "$id" >/dev/null 2>&1 && continue
  winget install --silent --accept-package-agreements --accept-source-agreements --id "$id"
  ok "$id"
done

info "done"
