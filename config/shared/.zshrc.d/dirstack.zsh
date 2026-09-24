# The directory stack.
#
# oh-my-zsh's lib/directories.zsh sets AUTO_PUSHD (plus PUSHD_IGNORE_DUPS and
# PUSHD_MINUS), so every `cd` is really a `pushd` and the stack is a history of
# where this shell has been — `dirs -v` to see it, `popd` to walk back, and the
# `1`-`9` aliases to jump. Two things here make that tidy rather than untidy.

# 1. A new shell starts with ~ on the stack, not with nothing.
#
# A new tmux pane inherits the directory of the one it was split from — that is
# `-c '#{pane_current_path}'` in tmux.conf, and iTerm2 does the same for a new
# tab — so a fresh shell lands deep inside a project with an *empty* stack. The
# first `cd ~` then pushes the project onto it, which is backwards: you wanted
# to arrive home with nothing behind you, and instead the stack is never clean.
#
# Seeding it the other way round gives both: you still start in the project,
# and one `popd` takes you home and leaves the stack empty.
#
# Written as an assignment to `dirstack` rather than the obvious `cd ~; dirs -c;
# cd -`, because `cd` in this shell is zoxide's function. That round trip would
# add two entries to zoxide's frecency database and fire every chpwd hook twice
# in order to finish exactly where it started. The `dirstack` parameter is tied
# to the real stack, so one assignment does it with no side effects at all.
#
# Guarded on the stack being empty so that re-sourcing ~/.zshrc mid-session does
# not pile up another copy, and skipped when the shell already starts at home —
# there, ~ on the stack would only mean a `popd` that goes nowhere.
if (( $#dirstack == 0 )) && [[ $PWD != $HOME ]]; then
  dirstack=( $HOME )
fi

# 2. cdc [dir] — cd, then forget how you got there.
#
# `dirs -c` alone clears the stack where you stand; this is the same thing with
# a destination, defaulting home. The argument goes through `cd`, so zoxide's
# frecency jumping still applies. `cd -` keeps working afterwards: OLDPWD is a
# separate variable and the stack never touches it.
cdc() { cd "${@:-$HOME}" && dirs -c }
