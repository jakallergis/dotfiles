# name: oh-my-zsh

# Step 15 installs zsh on macOS and Linux; Git Bash simply cannot have one.
has zsh || { warn "no zsh on this machine, skipping"; return 0; }

# Their installer honours an exported $ZSH and refuses if that folder exists —
# and our own .zshrc exports it — so both sides must mean the same directory.
omz=${ZSH:-$HOME/.oh-my-zsh}

if [ -d "$omz" ]; then
  info "oh-my-zsh already installed ($omz)"
else
  # The installer straight from their README. Both flags are load-bearing:
  #   --unattended  it ends with `exec zsh -l`, which would end this run here
  #                 and skip every remaining step
  #   --keep-zshrc  it would otherwise move the .zshrc that step 10 just
  #                 symlinked to .zshrc.pre-oh-my-zsh and write its template
  # It also skips chsh, which step 25 does properly (it copes without root).
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
    --unattended --keep-zshrc

  # A failed download leaves `sh -c ""`, which exits 0 — so check the outcome.
  [ -d "$omz" ] || die "oh-my-zsh did not install"
  ok "oh-my-zsh"
fi
