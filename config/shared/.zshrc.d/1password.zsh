# 1Password CLI.
#
# Inert without `op`, which is the point: a fresh machine or a Coder workspace
# loses nothing. Note that this file NEVER exports a secret by itself — it only
# defines two helpers, so nothing here costs anything at shell startup.
#
# The 1Password desktop app does not include `op`. Get it from
# https://1password.com/downloads/command-line (signed .pkg), then turn on
# Settings > Developer > "Integrate with 1Password CLI" in the app so `op`
# authenticates with Touch ID instead of asking for a password.
#
# Intended use is per project, not per shell: put op:// references in a .env
#
#     NPM_TOKEN=op://Private/npm registry/token
#
# and run commands through it with `oprun bun install`. The secret exists only
# in that one process and never lands on disk.

command -v op &>/dev/null || return

# secret <item/field> [vault] — read one field out of 1Password.
#   export NPM_TOKEN="$(secret 'npm registry/token')"
# The value never touches disk and only exists in that shell.
secret() {
  [[ -n $1 ]] || { print -u2 'usage: secret <item/field> [vault]'; return 1 }
  op read "op://${2:-Private}/$1"
}

# oprun <cmd…> — run a command with an .env whose values are op:// references
# rather than actual secrets, resolved just for that process.
oprun() {
  op run --env-file="${OP_ENV_FILE:-.env}" -- "$@"
}
