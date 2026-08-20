# name: druk
#
# --no-modify-path keeps the installer away from ~/.zshrc, which is a symlink
# into this repo; the PATH line lives in config/shared/.zshrc. The installer
# compares versions itself, so re-running it is also how you upgrade.

if [ "$OS" = linux ]; then
  has tar || die "tar is needed to unpack druk"
else
  has unzip || die "unzip is needed to unpack druk"
fi

PATH="$HOME/.druk/bin:$PATH"

curl -fsSL https://druk.letstri.dev/install | bash -s -- --no-modify-path

has druk || die "druk did not install"
ok "druk $(druk --version)"
