# name: Git identity
#
# A fresh machine — a Coder workspace especially — has either no identity or
# somebody else's, so this always checks rather than assuming. The values below
# are the source of truth; with -y they are applied without asking.

NAME="John A. Kallergis"
EMAIL="j.a.kallergis@gmail.com"

current_name=$(git config --global user.name || true)
current_email=$(git config --global user.email || true)

if [ "$current_name" = "$NAME" ] && [ "$current_email" = "$EMAIL" ]; then
  ok "already $NAME <$EMAIL>"
  return 0
fi

[ -n "$current_name$current_email" ] && warn "currently $current_name <$current_email>"

new_name=$(ask "git user.name?" "$NAME")
new_email=$(ask "git user.email?" "$EMAIL")

git config --global user.name "$new_name"
git config --global user.email "$new_email"
ok "$new_name <$new_email>"
