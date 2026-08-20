# name: Zsh
#
# Git Bash has no zsh and no way to get one. MSYS2 does (it has pacman), and
# WSL is the better answer for a zsh setup on Windows anyway.

if has zsh; then
  ok "already installed ($(zsh --version))"
  return 0
fi

if has pacman; then
  pacman -S --needed --noconfirm zsh
  ok "$(zsh --version)"
else
  warn "Git Bash has no zsh — use WSL (or MSYS2) for the zsh setup"
fi
