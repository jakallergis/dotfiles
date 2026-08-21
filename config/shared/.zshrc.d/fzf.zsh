# fzf behaviour. The payoff for having fd and bat installed: Ctrl+T becomes a
# fuzzy file browser with syntax-highlighted previews instead of a flat list.

command -v fzf &>/dev/null || return

# fd respects .gitignore and skips .git, and is much faster than find.
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_DEFAULT_OPTS='--height 60% --layout=reverse --border --info=inline'

# Preview the file under the cursor (bat if present, head otherwise).
if command -v bat &>/dev/null; then
  export FZF_CTRL_T_OPTS='--preview "bat --style=numbers --color=always --line-range :200 {}"'
else
  export FZF_CTRL_T_OPTS='--preview "head -200 {}"'
fi

# Alt+C jumps to a directory — show what is in it before committing.
if command -v eza &>/dev/null; then
  export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --colour=always {}"'
fi
