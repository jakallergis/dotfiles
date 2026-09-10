<div align="center">
<pre>
          _ ._  _ , _ ._
        (_ ' ( `  )_  .__)
      ( (  (    )   `)  ) _)
     (__ (_   (_ . _) _) ,__)
           ~~\ ' . /~~
         ,::: ;   ; :::,
        ':::::::::::::::'
</pre>
</div>

<h1 align="center">dotfiles</h1>

<p align="center">
  <em>One script. macOS, Linux and Git Bash. No framework, no submodules, no <code>Brewfile</code>.</em>
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-000000?logo=apple&logoColor=white">
  <img alt="Linux" src="https://img.shields.io/badge/Linux-000000?logo=linux&logoColor=white">
  <img alt="Git Bash" src="https://img.shields.io/badge/Git%20Bash-000000?logo=gitforwindows&logoColor=white">
  <img alt="zsh" src="https://img.shields.io/badge/shell-zsh-000000?logo=zsh&logoColor=white">
  <img alt="startup 0.28s" src="https://img.shields.io/badge/zsh%20startup-0.28s-000000">
</p>

---

Most dotfiles repos are a pile of symlinks and a `README` that says "run
`./install.sh`". This one is that too — but the installer is 240 lines of plain
bash with no library behind it, every tool comes from one version manager, and
the shell starts in **0.28 seconds** instead of the 1.25 it used to.

The part worth stealing is not the config. It is the written-down list of
**traps** — the installer that quietly appends to a `~/.zshrc` that is a symlink
into your repo; the `git include` that cannot work; the sourced file that fails
its step because its last line was a false conditional; the `-t name` that
matches by prefix and attaches you to the wrong session. Each one cost an
afternoon. They are all in [How it works](#how-it-works), with the reason.

Three things it is built to survive:

- **A machine without root.** Coder workspaces, containers, locked-down boxes.
  `install.sh` works out whether a privileged command *can* succeed and skips
  rather than fails; almost everything comes from [mise](https://mise.jdx.dev),
  which needs no package manager.
- **A dropped connection.** tmux is always installed and remote shells attach to
  their last session automatically, so an agent you set going yesterday is still
  going when you ssh back in. See [tmux](#tmux).
- **Three operating systems, one `.zshrc`.** Every block in it is guarded, so
  there is no `config/linux/.zshrc` to keep in sync.

---

## Install

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
Coder clones into `~/.config/coderv2/dotfiles`, not `$HOME`. `install.sh` is also
the name Coder auto-runs — its list is `install.sh, install, bootstrap.sh,
bootstrap, setup.sh, setup` plus `script/` variants — so one file serves both,
and from a checkout the bootstrap branch is skipped.

```sh
./install.sh              # ask before each step
./install.sh -y           # no questions
./install.sh -n           # print the plan only
./install.sh zsh fonts    # only steps whose path matches these words
DOTFILES_OS=linux ./install.sh -n   # see another machine's plan from here
```

Nothing is deleted. Anything already sitting where a symlink should go is moved
to `~/.dotfiles-backup/` first.

## What you get

| | |
| --- | --- |
| **shell** | zsh + [oh-my-zsh](https://ohmyz.sh) + [powerlevel10k](https://github.com/romkatv/powerlevel10k), autosuggestions, syntax highlighting |
| **tools** | one [mise](https://mise.jdx.dev) config installs node, bun, python, ruby, and `atuin bat delta eza fd fzf gh jq lazygit tmux zoxide` |
| **history** | [atuin](https://atuin.sh) on <kbd>Ctrl</kbd>+<kbd>R</kbd>, plus `ahist` for a cross-author fuzzy picker |
| **sessions** | tmux, auto-attached on any machine you reach over ssh — [see below](#tmux) |
| **git** | tracked identity, `gh`, ssh commit signing via 1Password, [delta](https://github.com/dandavison/delta) diffs, [lazygit](https://github.com/jesseduffield/lazygit) on `lg` |
| **editor** | [druk](https://druk.letstri.dev), falling back to vim |
| **fonts** | MesloLGS NF fetched from upstream, plus the vendored Hack and Meslo Powerline |
| **macOS** | Homebrew, a Finder/Dock `defaults` pass |

## Day to day

```sh
t                  # attach the session you were last in, or start `main`
t api              # attach or create the session `api`
t ls               # what is running
dots               # cd to this repo, wherever it was cloned
mkcd foo/bar       # mkdir -p, then cd
killport 3000      # kill whatever is holding the port
gclone <url>       # clone, then cd into it
lg                 # lazygit: stage, commit, rebase, stash, visually
ahist              # fuzzy-pick from everyone's shell history, agents included
als <word>         # search the ~400 aliases oh-my-zsh already defined
```

Inside tmux, no prefix needed (needs iTerm2's Left Option set to `Esc+`):

```
Option-d / Shift-Option-d   split right / below
Option-arrows               move between panes
Option-z                    zoom this pane, toggle
Option-s                    which Claude is waiting on me? (jumps to it)
Option-S                    pick a session
Option-=                    cycle layouts
Ctrl-b d                    detach, leave everything running
Ctrl-b ?                    every other binding
```

---

# How it works

This half of the file is the guide for anyone — human or agent — changing this
repo. It records the conventions and, more importantly, the traps that are
expensive to rediscover.

> `CLAUDE.md` and `AGENTS.md` are symlinks to this file, so every coding agent
> reads the same thing and there is one copy to keep true.

## install.sh

240 lines, no library, no framework. It finds the steps, asks, runs them.

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

## Writing a step

Available with no imports: `$OS` (macos|linux|windows), `$DOTFILES`, `$SUDO`
(empty when already root or when there is no sudo), `$CAN_ROOT`, `has`, `info`,
`ok`, `warn`, `err`, `die`, `confirm`, `ask`. Copy `steps/_template.sh`.

Four rules:

1. **Be idempotent.** Detect, then act. Most steps start with
   `has foo && { ok "already installed"; return 0; }`.
2. **The last line must succeed.** A sourced file returns its last command's
   status, so a trailing `is_linux && do_thing` that evaluates false *fails the
   step*. Wrap trailing conditionals in `if`. This has bitten twice.
3. **Guard, do not fail, for the wrong OS.** `[ "$OS" = windows ] && { warn
   "…"; return 0; }`.
4. **Never append to a shell rc file.** See below.

And before you write one at all: **can mise install this instead?** A step is
for things mise cannot do. Anything in its registry is one line of tracked
config, works without root, and needs no per-distro branch — which is how tmux
got added without a step.

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
   everything `.zshrc` probes for now comes from mise, and brew is down to git
   and jq.
3. Environment and PATH — `XDG_CONFIG_HOME` is exported here (see lazygit
   below for why that is not redundant); `typeset -U path` dedupes.
4. oh-my-zsh: settings, `fpath`, plugins, source. **`fpath` additions must come
   before this**, because sourcing oh-my-zsh runs `compinit`.
5. `$EDITOR` (druk, vim fallback).
6. Tool init — mise owns node, bun, python and ruby. **fzf before atuin**: `fzf --zsh`
   binds Ctrl+R, and the atuin block deliberately takes it back. **mise before
   the drop-ins**, because `tmux.zsh` in section 7 needs a `tmux` on PATH.
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
| `functions.zsh` | `mkcd`, `killport`, `dots`, `gclone`, `ahist` |
| `fzf.zsh` | fd/bat wiring for previews |
| `tmux.zsh` | `t`, and the remote auto-attach |
| `1password.zsh` | `secret`, `oprun` — inert without the `op` CLI |

**Vendor or install?** A single stable file (~100 lines) gets vendored here with
its upstream header intact. A multi-file project with its own releases (p10k
3.0M, zsh-syntax-highlighting 1.8M) gets an install step and a `git clone`.

**`zoxide init --cmd cd` renames its commands** — you get `cd`/`cdi`, not
`z`/`zi`. `aliases.zsh` puts the original names back.

**Check before adding an alias**: oh-my-zsh and its plugins define ~400 already.
`als <word>` searches them. `aliases.zsh` marks its one deliberate shadow.

## tmux

The reason it is here: a Coder workspace is a machine you reach over a network,
and the network is the part that breaks. tmux moves the shell off the connection
and onto the machine. Set an agent going, shut the laptop, ssh back tomorrow —
it is still there, still running, and you are looking at it again.

Three files, and **no install step**:

| | |
| --- | --- |
| `config/shared/.config/mise/config.toml` | one line installs it |
| `config/shared/.config/tmux/tmux.conf` | the configuration |
| `config/shared/.zshrc.d/tmux.zsh` | `t`, and the auto-attach |

**mise installs tmux, not apt and not brew.** Its `aqua:tmux/tmux-builds`
backend ships *static* binaries for linux and macOS on both arches: 2.6s, no
compiler, and — the point — **no root**. An `apt-get install tmux` step would
skip itself on exactly the machines that need tmux most, because `install.sh`
sets `CAN_ROOT=0` on a workspace outside sudoers. The entry is in table form
purely for the `os` gate:

```toml
tmux = { version = "latest", os = ["linux", "macos"] }
```

There is no Windows build, and an ungated entry fails `mise install` — and so
the whole step — on the Git Bash lane.

**Auto-attach is remote-only, and every guard below is a way it goes wrong.** The
condition lives in `_tmux_autoattach_wanted`, kept as a function rather than
inlined so that when a box does not attach you can run it and read `$?`.

| guard | what it stops |
| --- | --- |
| `$TMUX`, `$STY` | tmux runs `$SHELL` for every new pane. Without this the first pane attaches to the session it is already in, forever |
| `-o interactive` | `ssh host <cmd>`, scp, rsync and git-over-ssh all start a shell. None may be handed a full-screen program |
| `-t 1` | the same thing again, for anything without a terminal |
| `$TERM = dumb` | a captive shell inside an editor |
| `$TERM_PROGRAM`, `$VSCODE_INJECTION`, `$TERMINAL_EMULATOR` | VS Code and JetBrains reconnect their own remote terminals; tmux on top confuses both |
| `$SSH_CONNECTION`/`$SSH_TTY`/`$SSH_CLIENT`, `$CODER_AGENT_URL`/`$CODER_WORKSPACE_NAME` | the positive test — remote, or a Coder workspace |

`DOTFILES_TMUX_AUTOATTACH=0` in `~/.zshrc.local` turns it off for one machine.

**It is deliberately not `exec tmux`.** `exec` replaces the shell, so a typo in
`tmux.conf` — or a missing terminfo entry — would end the ssh session the
instant tmux gave up, on the remote box, with no shell left to fix it from.
Running it normally means a failure just leaves you at a prompt, and
<kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>d</kbd> lands you at one too.

**`-t name` matches by prefix.** `t api` on a box that already has `api-old`
attaches you to `api-old`, silently, on the wrong project. Every target in
`tmux.zsh` is written `-t "=$name"`; the `=` forces an exact match.

**`default-terminal` is chosen at runtime, not written down.** `TERM` has to
name a terminfo entry that the *system* has, and `tmux-256color` is missing from
slim container images and older macOS. tmux then refuses to start at all —
"missing or unsuitable terminal" — on the remote box, with no shell to fix it
from. So `tmux.conf` asks `infocmp` and falls back to `screen-256color`.

**Copy comes home over OSC 52.** `set -s set-clipboard on` makes tmux ask *your*
terminal to put the text on *your* clipboard, so a yank inside tmux on a Coder
box lands in the macOS clipboard with no X11 forwarding and no tunnel. iTerm2
needs it allowed once: Settings → General → Selection → "Applications in
terminal may access clipboard". The `@copy` user option is the belt-and-braces
for terminals that do not support it — `pbcopy`/`wl-copy`/`xclip` if the machine
has one, `cat` if it does not.

**`~/.config/tmux/tmux.conf` needs tmux ≥ 3.1.** Older versions read only
`~/.tmux.conf` and would start silently unconfigured. mise pins 3.7, so this is
theoretical here; `tmux -V` if you ever meet a tmux that arrived some other way.

**Nine keys need no prefix at all.** They are the ones that have to be as fast
as the terminal's own, and they are shaped after the iTerm2 shortcuts they
replace — one modifier along, because **tmux can never see Cmd**: macOS
terminals do not transmit it.

| | | replaces |
| --- | --- | --- |
| <kbd>Option</kbd><kbd>d</kbd> / <kbd>Shift</kbd><kbd>Option</kbd><kbd>d</kbd> | split right / below | iTerm2 ⌘D / ⇧⌘D |
| <kbd>Option</kbd><kbd>←</kbd><kbd>↓</kbd><kbd>↑</kbd><kbd>→</kbd> | move between panes | iTerm2 ⌘⌥-arrows |
| <kbd>Option</kbd><kbd>z</kbd> | zoom toggle | |
| <kbd>Option</kbd><kbd>s</kbd> | Claude status picker — [see below](#which-claude-is-waiting) | |
| <kbd>Option</kbd><kbd>S</kbd> | session picker (also stock <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>s</kbd>) | |
| <kbd>Option</kbd><kbd>=</kbd> | cycle layouts | |

**This needs one iTerm2 setting, and it is not tracked here.** Settings →
Profiles → Keys → **Left Option Key: `Esc+`**, leaving Right Option on `Normal`
so it still types é and —. Under the macOS default the Option key *composes
characters* (`Option-z` → `Ω`) and tmux never receives Meta at all, so every key
above — and tmux's own stock <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>Option-1…7</kbd>
layout keys — is silently dead. On Linux, Alt already works. Every root key has
a prefixed twin, so where Meta is unavailable nothing becomes unreachable; it
just costs a <kbd>Ctrl</kbd>+<kbd>b</kbd>.

**A root binding is taken from every program inside tmux, forever.** So each was
checked against a live `bindkey` before being taken, rather than assumed:

| key | what it shadows in zsh | |
| --- | --- | --- |
| `M-d` `M-D` | `kill-word` | the only real loss — `Ctrl-w` still deletes backwards |
| `M-Left`…`M-Right` | nothing, `undefined-key` | word movement here is on Ctrl-arrows and `M-b`/`M-f` |
| `M-z` | `execute-last-named-cmd` | |
| `M-s` `M-S` | `spell-word` | both spellings of it |
| `M-=` | nothing, `undefined-key` | |

`M-Enter` was the obvious pick for a layout key and was rejected: **Claude Code
uses Option-Enter for a newline**, and a root binding would have swallowed it in
every pane.

**Shift-Option-Space cannot be bound at all.** A terminal sends the same byte
for Space and Shift-Space, so tmux receives plain `M-Space` either way — `cat -v`
and pressing both proves it in five seconds. Separating them needs CSI-u
extended keys enabled in *both* iTerm2 and tmux, which changes how every key is
reported and upsets other TUIs. Hence `M-=`, for "make the panes equal".

### Which Claude is waiting

<kbd>Option</kbd>+<kbd>s</kbd> opens `config/shared/.config/tmux/claude-status.sh`
in a popup: every running Claude, ordered by who needs you, jumping to the pane
on Enter.

```
● waiting  limbic-dev-hub:1.1   ~/Git/limbic-dev-hub    1m
● busy     dotfiles:1.1         ~/dotfiles              0m
```

It took the key `choose-tree` had, because the plain session tree is already
one keystroke away on the stock <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>s</kbd>, and
this is the question actually worth a no-prefix key. `choose-tree` moved to
<kbd>Option</kbd>+<kbd>S</kbd>.

**Claude has no idea it is inside tmux**, so the join is three hops:
`claude agents --json` gives a pid and a status, `ps` turns the pid into a tty,
and `tmux list-panes` turns the tty into a pane. A Claude started outside tmux
is still listed, marked `not in tmux`, and simply cannot be jumped to.

**`display-popup -E` does not expand `#{...}` formats; `run-shell` does.** This
is why the binding is a `run-shell` that opens the popup rather than a
`display-popup` directly, and why the script has `--popup` and `--pick` modes.
Bind the popup straight to the key and the script receives the literal string
`#{q:client_name}`, tmux answers "can't find client", and the jump silently does
nothing — the picker looks perfect and Enter appears to do nothing at all.

**`switch-client` needs `-c`.** Inside a popup the current client *is* the
popup, which is about to close, so switching it moves nothing the user can see.
The client name has to be captured at binding time and passed down.

**Three things about drawing fzf inside `display-popup`**, all of which looked
like layout problems and were not:

| | |
| --- | --- |
| `$FZF_DEFAULT_OPTS` leaks in | it carries `--height 60% --border` for inline use in a shell, where both are right. In a popup that leaves 40% of the box empty below the preview and draws a second border inside the popup's own. fzf reads the env var before the flags on the command line, so the script restates `--height=100% --border=none` to win |
| `tput cols` lies | it reported **80** — the terminfo default — in a 154-column popup, because it never sees the popup. `$COLUMNS` is unset and `#{client_width}` gives the client *behind* the popup (170). Only `stty size` reports the popup: `26 154` |
| fzf's responsive syntax misbehaved | `--preview-window='right,58%,<120(down,55%)'` forced the stacked alternative even in a 163-column popup on fzf 0.74.3. The script branches on width itself instead — a line longer and predictable |

The split is **25/75** — the list carries little and the preview carries a whole
conversation — and stacks below ~120 columns, where two panes do not fit.

**The row columns are computed from the split width, not padded to a constant.**
A fixed-width row leaves dead space in a wide split and gets ellipsised in a
narrow one, and both were visible before. `list_w` is a quarter of the popup
less fzf's two-column pointer gutter and the one-column border; status and age
are fixed, and the name takes whatever is left. The tmux location column
appears only when there is room for it — at 25% there is not, so `--preview`
prints the location as a header above the pane contents instead. That is also
why the preview is a mode of the script rather than an inline `--preview`
string. `--list` overrides all of this and uses the full terminal, since it is
printing to a shell rather than into a quarter of a popup.

`claude agents --json` is the load-bearing dependency, and it is not in
`claude --help`'s documented surface — treat it as liable to change. `jq` parses
it, which is why jq moved from Homebrew into the mise list: it existed on the
Mac and nowhere else, and `agents.sh`-style pipelines fail *silently* without
it. `claude-status.sh --list` prints the same table with no terminal, which is
both a shell convenience and how it gets tested.

Considered and not adopted:
[tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager),
which is where this idea came from. Its picker half is excellent and works on
plain panes; its other half puts each Claude in a dedicated detached
`claude-<hash-of-cwd>` session, which collides twice here — an invisible
detached session would keep `forget-on-teardown.sh` from ever seeing "no
sessions left", and hashing by directory maps all four dev-hub panes onto one
session, the same collision that ruled out `claude --continue`.

The prefix is the stock <kbd>Ctrl</kbd>+<kbd>b</kbd>, so anything you read
elsewhere applies as written. What is not stock:

| | |
| --- | --- |
| <kbd>&#124;</kbd> <kbd>-</kbd> <kbd>%</kbd> <kbd>"</kbd> | split, **keeping the current directory** — tmux's default starts you in `$HOME` |
| <kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd> | move between panes (repeatable — hold the prefix once, then tap) |
| <kbd>H</kbd> <kbd>J</kbd> <kbd>K</kbd> <kbd>L</kbd> | resize |
| <kbd>Tab</kbd> | last window (`l` used to be this, and `hjkl` wanted it) |
| <kbd>r</kbd> | reload `tmux.conf` |
| <kbd>m</kbd> | toggle the mouse — off is how you get native terminal selection back |
| <kbd>S</kbd> | flag this window once it has been quiet for 30s: *tell me when the agent stops typing* |
| <kbd>v</kbd> <kbd>y</kbd> in copy mode | select / copy, vi keys |

Windows and panes are 1-indexed, scrollback is 100k lines, and
`aggressive-resize` is on so one forgotten phone-sized client does not squeeze
the laptop.

**Surviving the machine going away** is the one thing tmux cannot do alone —
see [Reboot persistence](#reboot-persistence).

## Reboot persistence

A tmux server holds its sessions in memory, so a restart — or a Coder workspace
auto-stopping — takes every pane with it. `steps/shared/35-tmux-plugins.sh`
clones [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) (writes
the layout to disk) and
[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) (does it on a
timer, and restores when the server next starts).

Measured on a five-pane, two-window session killed with `kill-server`: sessions,
windows, panes, layout, each pane's working directory and the visible scrollback
all came back, in under a second.

**No TPM.** The tmux plugin manager is the usual way in, but both plugins ship a
standalone `.tmux` entrypoint, so two `run-shell` lines load them directly —
the same call as the zsh plugins in step 22.

**Section 7 of `tmux.conf` must stay last, and this is the trap.** continuum has
no timer of its own: it schedules saves by prepending `#(continuum_save.sh)` to
`status-right` and relying on tmux re-rendering the status line every
`status-interval` seconds. Any `set -g status-right` *after* continuum loads
wipes that, and automatic saving stops — silently, with `@continuum-restore`
still reporting `on`. Check with:

```sh
tmux show-options -gv status-right | grep -c continuum_save   # must be 1
```

**It only saves while a client is attached**, for the same reason: tmux does not
render a status line nobody is looking at. Verified — 40 seconds detached
produced nothing, 80 seconds attached produced a save. In practice the last save
reflects your last attached layout, which is the right one; before a planned
restart, <kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>Ctrl</kbd>+<kbd>s</kbd> forces one.
<kbd>Ctrl</kbd>+<kbd>b</kbd> <kbd>Ctrl</kbd>+<kbd>r</kbd> restores by hand.

**Closing every pane on purpose is not undone at the next start.** Persistence
that cannot tell "the machine took my panes away" from "I dismissed them" is
just an inability to quit: `exit` out of every pane, run `t`, and the last
periodic save rebuilds all of them. `config/shared/.config/tmux/forget-on-teardown.sh`
runs from a `session-closed` hook and, when no sessions are left, renames the
saved state out of the way so the next start begins clean.

Two things make that work, and **neither half works alone**:

| | |
| --- | --- |
| `set-hook -g session-closed` | fires the script as sessions go away |
| `set -g exit-empty off` | without it the hook never runs for the *last* session — the one that matters. Verified: with tmux's default `exit-empty on`, the hook fires closing session 2 of 2 and is simply skipped for the last one, because the server is already shutting down |

The script then calls `tmux kill-server` itself, so the empty server does not
linger — `exit-empty off` exists only to buy the hook a moment to run.

It renames rather than deletes: `last` is a symlink and the timestamped state
file behind it is untouched, so `mv last.closed last` in the resurrect directory
undoes an accidental teardown. It also asks tmux for `@resurrect-dir` rather
than assuming the default path, which is what makes it testable against a
throwaway save directory.

Verified both ways round: exiting every pane leaves `last.closed` and a fresh
`main` next time, while `kill -9` on the server leaves `last` intact and the
panes come back with their directories.

**continuum does nothing when a second tmux server is running.** Both
`continuum_save.sh` and `continuum_restore.sh` bail out on
`another_tmux_server_running`, deliberately, so two environments cannot
overwrite each other's state. Worth knowing before concluding the config is
broken — it is also what makes testing this on a machine with a live session
misleading, since a throwaway `tmux -L test` server counts.

**`t` starts the server before attaching, and cleans up after itself.** Starting
a server is what triggers the restore, but a server with no sessions exits
immediately, so the restore needs one to land beside. `t` makes a placeholder
called `__restore` and drops it once the saved sessions are back. The name
matters: the saved state usually *contains* a session called `main`, so a
placeholder by that name would get killed instead of the restored one.

**Restored Claude panes open the session picker, not `--continue`.** This looks
like the wrong choice for about ten seconds. Claude keys its history by
directory: everything started in `~/Git/dev-hub` lands in the one bucket
`~/.claude/projects/-Users-Giannis-Git-dev-hub`. So `--continue` resolves to that
directory's newest transcript — and when several panes share a directory, which
is the normal way to work here, all of them would reopen the *same* conversation
and start writing over each other.

`claude --resume` with no argument opens the picker instead, so each pane asks
which conversation belongs in it. One keypress per pane, and it cannot silently
put four clients on one transcript.

The match is against the `ps` command line, **not** `#{pane_current_command}`,
and that distinction is load-bearing here. `~/.local/bin/claude` is a symlink to
a version-numbered binary, so tmux reports the pane as `2.1.263` while `ps` still
shows `claude`. A rule written against `pane_current_command` would look right,
work once, and break at the next Claude Code update.

Nothing else is restored: a dev server or a build is gone, by design.

**`steps/macos/36-tmux-boot.sh` brings the server up at login**, so the sessions
are already restored before a terminal is opened and `t` attaches instantly. It
writes two generated files — `~/.local/bin/dotfiles-tmux-boot` and a
`~/Library/LaunchAgents` plist — the same tracked-intent / generated-fact split
as `~/.config/git/config` in step 40. Neither can be portable: the plist needs an
absolute path and the script needs a hardcoded `PATH`, because launchd hands a
job `/usr/bin:/bin:/usr/sbin:/sbin` and nothing else. tmux is found through
mise's `latest` symlink, which mise repoints on upgrade.

**continuum's own `@continuum-boot` is deliberately not used.** On macOS it
drives AppleScript that opens Terminal.app — iTerm2 only via a profile that must
be named `Tmux` — resizes the window to fill the desktop, and types a bare
`tmux`, which starts a session *beside* the restored ones: the exact thing `t`
exists to prevent. It also needs Automation permission. The step does the one
useful part and nothing else.

```sh
launchctl print gui/$(id -u)/com.jakallergis.tmux     # check it is loaded
launchctl bootout gui/$(id -u)/com.jakallergis.tmux   # turn it off
```

## lazygit

Git as a dashboard rather than a command: five always-visible panels, `1`-`5` to
jump between them, mouse on by default. Installed by mise like everything else,
configured by `config/shared/.config/lazygit/config.yml`, and aliased to `lg`.

**On macOS it does not read `~/.config` unless `XDG_CONFIG_HOME` is set.** With
the variable unset lazygit uses `~/Library/Application Support/lazygit/`, so a
symlinked config here works on Linux and is ignored in silence on the Mac — no
error, the settings simply do nothing. `.zshrc` therefore exports
`XDG_CONFIG_HOME=$HOME/.config` even though that is already the XDG default when
unset: the default is what the *spec* says, not what every tool does. Check with
`lazygit --print-config-dir`.

**delta is wired in through `git.diffRenderers`, not `git.paging`.** The old key
was removed in lazygit 0.64 and a config still using it is accepted and quietly
does nothing. The replacement is picky in a way worth writing down: for
`type: stdinFilter` the flags must be part of `command`, because a sibling
`args:` list is rejected — and lazygit's way of reporting a bad config is to
print one line and **exit 0**, which reads as "it just won't start".

```yaml
git:
  diffRenderers:
    - type: stdinFilter
      name: delta
      colorArg: always
      command: delta --paging=never
```

**Branch names in the graph took some finding.** The Commits panel shows a
`(branch)` label against each ref — but *only in fullscreen screen mode*. This
is not a width problem: at 240 columns, and with `sidePanelWidth` pushed to
`0.45`, it still renders the compact form. <kbd>+</kbd> cycles normal → half →
full and the labels appear; <kbd>_</kbd> goes back. Two config keys help:

| | |
| --- | --- |
| `git.log.showWholeGraph: true` | include commits from branches you are not on. Without it they are absent entirely, so there is nothing to branch *from* and the graph is a straight line. <kbd>Ctrl</kbd>+<kbd>l</kbd> toggles it live |
| `git.allBranchesLogCmds` | the Status panel's <kbd>a</kbd> view. lazygit's default passes `--pretty=medium` — five lines per commit, which pushes the graph off screen. Replaced with a one-line format; `a` cycles the list so the verbose original is still there on a second press |

<kbd>a</kbd> in the Status panel is the closest thing to `git log --graph --all
--decorate`, and after that change it is readable. In the Commits panel,
<kbd>*</kbd> highlights just the commits belonging to the current branch.

`gui.nerdFontsVersion: "3"` draws file-type and branch icons. It depends on the
terminal actually being set to a Nerd Font — see [Fonts](#fonts).

`update.method: never`, because mise owns the binary and pins it in the tracked
mise config; a self-update prompt could only produce drift between the two.

Considered and not chosen: **gitui** (Rust, half the binary, faster on huge
repos, but keyboard-only and fewer operations) and **gitu** (a magit clone —
one scrolling buffer, excellent if you come from Emacs, almost no visual
affordance otherwise). All three are in mise's registry, so swapping is a
one-line diff.

## Fonts

`steps/shared/30-fonts.sh` installs from two places, and the split is the whole
design:

| | |
| --- | --- |
| `fonts/` | committed to this repo, copied as they are (Hack, Meslo Powerline) |
| MesloLGS NF | four weights fetched from `romkatv/powerlevel10k-media` |

**MesloLGS NF is fetched, not committed, and that is deliberate.** It is ~10MB
across four weights — four times everything else in `fonts/` put together.
Committing it would put that in every clone forever, including the Coder
workspaces that re-clone this repo on each create and have **no display to
render a font on**. `install.sh` already needs the network for oh-my-zsh, p10k,
mise and druk, so fetching costs a machine running this step nothing it does not
already have. It comes from romkatv's own media repo rather than the Nerd Fonts
release because those are the exact four files `p10k configure` offers to
install, so a machine set up either way ends up identical.

**Each download lands via `mktemp` and is moved into place only on success.**
Writing straight to the destination leaves a truncated font behind when the
network drops, and the "already there?" test at the top of the loop would then
skip it on every future run — a broken font that repairs itself never.

**Setting the terminal to it is manual, and cannot be otherwise.** The font is a
preference of iTerm2 / Quake / whatever is drawing the pixels, not of anything
this repo owns:

> iTerm2 → Settings → Profiles → Text → Font → **MesloLGS NF**

Until that is done the font is installed and unused, and everything below will
render tofu boxes instead of icons.

Three tracked settings depend on it, so they move together:

| | |
| --- | --- |
| `.p10k.zsh` | `POWERLEVEL9K_MODE=nerdfont-v3` |
| `.config/lazygit/config.yml` | `gui.nerdFontsVersion: "3"` |
| `.zshrc.d/aliases.zsh` | `eza --icons=auto` on `ls`/`ll`/`la`/`lt` |

`--icons=auto` rather than `always` on purpose: eza then draws glyphs only when
writing to a terminal, so `ls | grep` and anything reading the output stays
clean.

**The p10k edit is two lines, by hand, and worth knowing about.** `p10k
configure` decides `POWERLEVEL9K_MODE` from the "can you see this icon?"
question, and it had been answered *no* — leaving `mode=powerline` and an
uncommented `POWERLEVEL9K_LOCK_ICON='∅'` substituting a plain glyph for one the
font lacked. Both were changed back toward the upstream rainbow template rather
than regenerating the file, which would have meant re-answering the whole wizard
and re-deciding the styling. Diffing against
`~/.oh-my-zsh/custom/themes/powerlevel10k/config/p10k-rainbow.zsh` is how you
tell a wizard font-fallback from a template default — the empty
`VCS_BRANCH_ICON` and `'?'` untracked marker look like fallbacks and are not;
they are identical upstream. Note the template still says the older
`nerdfont-complete` (the v2 glyph positions); MesloLGS NF is patched to v3.

Re-running `p10k configure` regenerates the file **through the symlink, into
this repo**, so it shows up as a diff to commit — same as `mise use -g`.

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

`tmux.zsh` costs one `command -v` and does not appear in the measurement.

## Testing

```sh
./install.sh -n                        # plan
DOTFILES_OS=linux ./install.sh -n      # another lane's plan
HOME=/tmp/fakehome ./install.sh -y symlinks   # destructive steps, safely
zsh -n config/shared/.zshrc            # syntax
zsh -n config/shared/.zshrc.d/*.zsh
script -q /dev/null zsh -i -c exit     # a clean startup needs a pty; without
                                       # one, gitstatus fails spuriously
cat -v                                 # then press a key to see what it sends
```

**`HOME=/tmp/fake` does not sandbox mise.** It resolves its home from the OS
passwd entry, not `$HOME`, so it will read your real `~/.config/mise/config.toml`
and then fail a trust check. Use `MISE_CONFIG_DIR` and `MISE_DATA_DIR` instead.

**Checking tmux.conf without touching your sessions** — a private socket and a
throwaway server. tmux reports config errors to the attaching client, so
`show-messages` is where they surface:

```sh
tmux -L probe -f config/shared/.config/tmux/tmux.conf new-session -d -s x 'sleep 60'
tmux -L probe show-messages          # config errors land here
tmux -L probe show-options -s        # server options: default-terminal, set-clipboard
tmux -L probe show-options -g        # session options
tmux -L probe list-keys -T prefix
tmux -L probe kill-server
```

`TMUX_TMPDIR` also isolates a test server, but a unix socket path caps out
around 104 characters — keep the directory short or every command fails with
"File name too long".

**Testing the auto-attach means faking a pty and faking tmux.** `script -q
/dev/null` needs a controlling tty and does nothing without one — which looks
like a pass, because the negative cases still report "did not attach". Drive
`pty.fork()` from python instead, put a stub `tmux` that logs its arguments
first on `PATH`, and assert on the log:

```sh
env SSH_CONNECTION=1.2.3.4 ZDOTDIR=… PATH=stub:$PATH python3 pty_run.py zsh -i -c exit
```

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
- **tmux-resurrect / tmux-continuum are in** — see
  [Reboot persistence](#reboot-persistence). The objection recorded here was
  that they drag in TPM; they do not, both ship a standalone `.tmux` entrypoint
  that `run-shell` loads directly.
- **The prefix is stock <kbd>Ctrl</kbd>+<kbd>b</kbd>.** Chosen so that every
  tmux answer on the internet applies unedited, and so <kbd>Ctrl</kbd>+<kbd>a</kbd>
  stays beginning-of-line in zsh. One line in `tmux.conf` to change your mind.
