# name: Login shell
#
# Separate from the oh-my-zsh step: making zsh the login shell has nothing to
# do with the framework, and it is worth being able to re-run on its own.

has zsh || { warn "no zsh on this machine, skipping"; return 0; }
zsh_bin=$(command -v zsh)

if [ "$(basename "${SHELL:-}")" = zsh ]; then
  ok "already the login shell ($zsh_bin)"
  return 0
fi

# Try chsh first. It needs root, and refuses any shell missing from /etc/shells.
if [ "$(id -u)" = 0 ] || [ -n "$SUDO" ]; then
  if ! grep -qx "$zsh_bin" /etc/shells 2>/dev/null; then
    printf '%s\n' "$zsh_bin" | $SUDO tee -a /etc/shells >/dev/null || true
  fi
  if $SUDO chsh -s "$zsh_bin" "$(id -un)"; then
    ok "login shell is now $zsh_bin (from your next login)"
    return 0
  fi
fi

# No root, or chsh refused — a Coder workspace, a container, a locked-down box.
# Whatever shell does log in hands over to zsh instead.
warn "could not change the login shell, switching from the rc file instead"

for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  grep -q 'dotfiles: use zsh' "$rc" 2>/dev/null && continue
  cat >>"$rc" <<TRAMPOLINE

# dotfiles: use zsh (the login shell could not be changed)
case \$- in
  *i*)
    if [ -z "\${ZSH_VERSION:-}" ] && [ -x "$zsh_bin" ]; then
      export SHELL="$zsh_bin"
      exec "$zsh_bin" -l
    fi
    ;;
esac
TRAMPOLINE
  ok "added to $(basename "$rc")"
done
