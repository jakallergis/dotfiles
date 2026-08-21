# dotfiles

Config for macOS, Linux and Windows (Git Bash), applied by one script.

```sh
git clone https://github.com/jakallergis/dotfiles ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

Or, with nothing cloned yet — `install.sh` bootstraps itself:

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jakallergis/dotfiles/master/install.sh)"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/jakallergis/dotfiles/master/install.sh)" "" -y     # to pass flags, $0 needs a placeholder
```

That block is POSIX sh and runs before anything bash-specific, because `sh -c`
ignores the shebang. It clones to `$DOTFILES_DIR` (default `~/.dotfiles`) and
`exec`s the real copy. Nothing else hardcodes that path: `dots()` finds the repo
by reading the `~/.zshrc` symlink, which is what makes it work under Coder too —
Coder clones into `~/.config/coderv2/dotfiles`, not `$HOME`. `install.sh` is also the name Coder auto-runs — its list
is `install.sh, install, bootstrap.sh, bootstrap, setup.sh, setup` plus
`script/` variants — so one file serves both, and from a checkout the bootstrap
branch is skipped.

This file is the guide for anyone — human or agent — changing this repo. It
records the conventions and, more importantly, the traps that are expensive to
rediscover.

## install.sh

186 lines, no library, no framework. It finds the steps, asks, runs them.

- A **step** is `steps/<lane>/<NN>-<slug>.sh`. Lanes are `shared`, `macos`,
  `linux`, `windows`.
- `shared` and the detected OS lane are merged into **one list sorted by
  filename**, so `shared/10-symlinks.sh` runs between `macos/05-homebrew.sh`
  and `macos/15-zsh.sh`. Leave gaps in the numbering.
- A file in the OS lane **replaces** a shared file of the same name.
- `_*` and `.*` files are ignored.
- The display name comes from a `# name:` comment, else the filename.
- Each step runs in `( set -e; . "$step" )` — a standalone subshell, never an
  `if` condition, because bash suspends errexit inside conditions and the
  suspension leaks into subshells. Get that wrong and a step sails past a
  failed command reporting success.
- A failing step stops the run and prints how to re-run just that one.

```sh
./install.sh              # ask before each step
./install.sh -y           # no questions
./install.sh -n           # print the plan only
./install.sh zsh fonts    # only steps whose path matches these words
DOTFILES_OS=linux ./install.sh -n   # see another machine's plan from here
```

## Writing a step

Available with no imports: `$OS` (macos|linux|windows), `$DOTFILES`, `$SUDO`
(empty when already root or when there is no sudo), `has`, `info`, `ok`, `warn`,
`err`, `die`, `confirm`, `ask`. Copy `steps/_template.sh`.

Four rules:

1. **Be idempotent.** Detect, then act. Most steps start with
   `has foo && { ok "already installed"; return 0; }`.
2. **The last line must succeed.** A sourced file returns its last command's
   status, so a trailing `is_linux && do_thing` that evaluates false *fails the
   step*. Wrap trailing conditionals in `if`. This has bitten twice.
3. **Guard, do not fail, for the wrong OS.** `[ "$OS" = windows ] && { warn
   "…"; return 0; }`.
4. **Never append to a shell rc file.** See below.

## The rc-file trap

`~/.zshrc` is a **symlink into this repo**. Any installer that appends to it is
committing to git. Every tool needs a different lever, and they are easy to get
wrong:

| tool | how it is stopped |
| --- | --- |
| oh-my-zsh | `--unattended --keep-zshrc` (also stops its `exec zsh -l`, which would end the run) |
| druk | `--no-modify-path` |
| p10k | its own `[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh` line, **verbatim**, so the wizard's grep finds it and stops adding a second copy |
| mise | nothing needed — its installer only *prints* the activation line |

Most of this class of problem went away when mise took over tool installation:
mise never touches shell config. The levers that used to be needed here, kept
because they are easy to get wrong if a tool ever comes back on its own
installer: nvm `PROFILE=/dev/null`; bun/bum `SHELL=none` (no flag exists, and
bun appends **unconditionally with no dedup check**); atuin
`ATUIN_NO_MODIFY_PATH=1`, which also skips writing `~/.atuin/bin/env`; fzf
`install --bin`.

The shell wiring those installers want to add belongs in `config/shared/.zshrc`
or a drop-in — never in a step.

## config/ and symlinks

`steps/shared/10-symlinks.sh` links every **top-level** entry of
`config/shared/` and `config/<os>/` into `$HOME` under the same name. Add a
file, get a symlink; there is no list to maintain. Anything already at the
destination moves to `~/.dotfiles-backup/` first — nothing is deleted.

- An OS lane file replaces a shared one **of the same name**.
- **Directories are replaced wholesale, not merged.** A
  `config/macos/.zshrc.d/` would shadow the entire shared one. OS-specific
  drop-ins therefore live in the shared directory with a guard:
  `[[ $OSTYPE == darwin* ]] || return`.
- **`MIRROR=".config .claude .agents"`** — those three are descended into and
  linked file by file, never as a directory, because other tools write into them
  too (`~/.claude` holds a 1 MB history file and 678 plugin files; `~/.config/gh`
  holds an OAuth token). Everything else is linked whole, which is why adding a
  file to `config/shared/.zshrc.d/` needs no re-run.

**What belongs in `config/`: the delta, never the whole file.** Four boxes —
intent (hand-written and small, e.g. `.config/git/ignore`) is tracked; defaults
you happen to agree with are never tracked, because not tracking them is how you
inherit upstream improvements; tool state and secrets are never tracked
(`.config/gh/hosts.yml` holds an OAuth token); and a config that *is* the source
of truth is tracked. Worked example: atuin's own config.toml is 403 lines of
which one is a real setting, so `config/shared/.config/atuin/config.toml` is that
one line. Most tools can print just the delta — `git config --global --list`,
`npm config ls` without `-l`.

`settings/` is an archive of app preferences (iTerm2, Alfred, Xcode…). It is
**not** symlinked; export to it by hand.

## Split config: tracked intent, generated machine facts

`~/.gitconfig` is tracked (identity, ssh signing, delta, gh credential helper by
PATH not by absolute path). The one value that cannot be portable — the path to
1Password's `op-ssh-sign`, different on every OS — is written to
**`~/.config/git/config`** by `steps/shared/40-git.sh`.

Git reads that file *in addition to* `~/.gitconfig`, and before it, so the
tracked file wins any clash. Two things that do **not** work here, both tested:
an `[include] path = ~/.gitconfig.local` (git does not expand `~/` in
include.path) and a relative include (git resolves it against the including
file's directory, which through the symlink is this repo).

Same shape elsewhere: `~/.zshrc.local` for secrets, `mise use -g` writing
through the symlinked mise config.

## .zshrc

Eight numbered sections, and three of the orderings are load-bearing:

1. **p10k instant prompt** — must be first; nothing above it may print or read.
2. **Homebrew shellenv** — must precede any `command -v` looking for a
   brew-installed tool, or that block silently no-ops. Defensive at the moment:
   everything `.zshrc` probes for now comes from mise, and brew is down to git,
   gh and jq.
3. PATH (`typeset -U path` dedupes).
4. oh-my-zsh: settings, `fpath`, plugins, source. **`fpath` additions must come
   before this**, because sourcing oh-my-zsh runs `compinit`.
5. `$EDITOR` (druk, vim fallback).
6. Tool init — mise owns node, bun, python and ruby. **fzf before atuin**: `fzf --zsh` binds Ctrl+R, and the
   atuin block deliberately takes it back.
7. `~/.zshrc.d/*.zsh`, in filename order, **last** so a drop-in can override
   any binding above it.
8. `~/.zshrc.local` — untracked, per-machine, where tokens go.

Every block is guarded, so one shared `.zshrc` serves all three OSes. No
`config/linux/.zshrc` is needed.

## ~/.zshrc.d drop-ins

| file | what |
| --- | --- |
| `options.zsh` | the few `setopt`s oh-my-zsh does not already set |
| `aliases.zsh` | listing, bun, git, editing |
| `functions.zsh` | `mkcd`, `killport`, `dots`, `gclone` |
| `fzf.zsh` | fd/bat wiring for previews |
| `1password.zsh` | `secret`, `oprun` — inert without the `op` CLI |

**Vendor or install?** A single stable file (~100 lines) gets vendored here with
its upstream header intact. A multi-file project with its own releases (p10k
3.0M, zsh-syntax-highlighting 1.8M) gets an install step and a `git clone`.

**`zoxide init --cmd cd` renames its commands** — you get `cd`/`cdi`, not
`z`/`zi`. `aliases.zsh` puts the original names back.

**Check before adding an alias**: oh-my-zsh and its plugins define ~400 already.
`als <word>` searches them. `aliases.zsh` marks its one deliberate shadow.

## Startup budget

Measured on an M-series Mac, steady state. Total **≈ 0.28s**, down from ~1.25s.

| | |
| --- | --- |
| oh-my-zsh + ~15 plugins | ~180ms |
| `brew shellenv` (fork) | ~37ms |
| `mise activate`, `fzf --zsh`, `zoxide init`, `atuin init` | ~13-19ms each |
| bare `zsh -f` | ~9ms |

How it got there, since the numbers are the argument for the design:

| | |
| --- | --- |
| `source $NVM_DIR/nvm.sh` + a `load-nvmrc` chpwd hook | **~600ms**, replaced by mise activate at ~18ms |
| `pyenv init` + `rbenv init` forks | **~170ms**, gone — mise owns python and ruby |

oh-my-zsh is now the largest single item by a wide margin. p10k's instant prompt
makes the prompt appear in ~30ms; it does not reduce the total. Profile with
`zmodload zsh/zprof` — but note zprof only sees *functions*, so it misses
`eval "$(… init)"` forks and its nested totals double-count. Time each piece as
its own process instead.

## Testing

```sh
./install.sh -n                        # plan
DOTFILES_OS=linux ./install.sh -n      # another lane's plan
HOME=/tmp/fakehome ./install.sh -y symlinks   # destructive steps, safely
zsh -n config/shared/.zshrc            # syntax
script -q /dev/null zsh -i -c exit     # a clean startup needs a pty; without
                                       # one, gitstatus fails spuriously
cat -v                                 # then press a key to see what it sends
```

**`HOME=/tmp/fake` does not sandbox mise.** It resolves its home from the OS
passwd entry, not `$HOME`, so it will read your real `~/.config/mise/config.toml`
and then fail a trust check. Use `MISE_CONFIG_DIR` and `MISE_DATA_DIR` instead.

For key bindings, drive a real pty with `expect`: type a line, send the key
bytes, then type a marker and check where it landed. To prove an installer does
not touch your rc files, put decoy `.zshrc`/`.bashrc`/`.profile` in a fake
`$HOME` and diff them afterwards.

## Open decisions

- **mise's tool list lives in `config/shared/.config/mise/config.toml`**, not in
  `55-mise.sh`, which just runs `mise install`. `mise use -g <tool>` writes
  through the symlink into the repo (verified: mise writes in place rather than
  replacing the symlink), so adding a tool is a diff to commit.
- **`op` CLI is installed by no step**, and the 1Password desktop app does not
  ship it (the bundle only has `op-ssh-sign`). `1password.zsh` defines helpers
  and exports nothing, so it stays inert until `op` is installed by hand. On a
  headless box it needs a service account token.
