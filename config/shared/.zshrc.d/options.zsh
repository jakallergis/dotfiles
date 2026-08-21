# zsh options that oh-my-zsh does not already set.
#
# Every line says what it does, because a bare `setopt` list is unreadable six
# months later. Check any of these with `[[ -o <option> ]] && echo on`.

# Write as much history to disk as is kept in memory. oh-my-zsh sets
# HISTSIZE=50000 but SAVEHIST=10000, so 40k lines were being dropped on exit.
SAVEHIST=$HISTSIZE

# When a command repeats, keep only the newest copy in history.
setopt HIST_IGNORE_ALL_DUPS

# Strip pointless whitespace out of a command before it is saved.
setopt HIST_REDUCE_BLANKS

# Sort file2 before file10 in globs, instead of alphabetically.
setopt NUMERIC_GLOB_SORT

# Extra glob syntax: **/ recurses, ^foo negates, (#i) makes a pattern
# case-insensitive, *(.) matches plain files only, *(om[1]) the newest file.
setopt EXTENDED_GLOB

# Which characters count as part of a word for Alt+arrow and Alt+Backspace.
# Empty means only letters and digits do, so Alt+Backspace eats one path
# segment rather than the whole path. Currently inherited from oh-my-zsh's
# lib/completion.zsh; pinned here so it survives if oh-my-zsh ever goes.
WORDCHARS=''
