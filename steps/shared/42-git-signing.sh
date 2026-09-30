# name: Commit signing
#
# One signing key per machine, created here, never shared and never in the repo.
#
# What this replaces: a literal `user.signingkey = ssh-rsa AAAA…` in the tracked
# config. Two things were wrong with it. A literal key makes git hand the
# signing job to ssh-keygen with no file to read, so ssh-keygen asks an *agent*
# for the private half — and on a box with no SSH_AUTH_SOCK, which is every
# non-interactive shell and every Coder workspace, that is
# `error: Couldn't get agent socket?` followed by `failed to write commit
# object`. You cannot commit at all. And since the key existed on exactly one
# machine, nowhere else could ever have signed anyway.
#
# The fix is to name the public key *file*. `ssh-keygen -Y sign -f key.pub`
# strips the .pub, finds the private half beside it and signs directly, with no
# agent anywhere — verified with SSH_AUTH_SOCK unset. Naming the .pub rather
# than the private key is also what GitHub documents and what allowedSignersFile
# wants, and it keeps private paths out of config entirely.
#
# No passphrase, on purpose. A passphrase can only be supplied by an agent or a
# prompt, which is the exact failure being fixed. This key signs and does
# nothing else: it grants no access, and anyone who could read it already has
# the filesystem. Authentication keys keep their passphrases.
#
# Nothing here may stop you committing. If a key cannot be made, signing is
# switched off for this machine and the step says so.

has git || die "git is missing"

key="$HOME/.ssh/id_ed25519_signing"
signers="$HOME/.ssh/allowed_signers"
tracked_signers="$HOME/.config/git/allowed_signers"
title="$(uname -n) signing"

# --- the key ---------------------------------------------------------------
if ! has ssh-keygen; then
  warn "no ssh-keygen here — signing stays off on this machine"
  git config --global --unset-all commit.gpgsign 2>/dev/null || true
  git config --global --unset-all gitbutler.signCommits 2>/dev/null || true
  return 0
fi

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh" 2>/dev/null || true

if [ -f "$key" ]; then
  info "using the existing key at ~/.ssh/id_ed25519_signing"
else
  # -N '' is the no-passphrase decision above. Existing keys are never touched:
  # this branch only runs when the file is absent.
  ssh-keygen -t ed25519 -N '' -C "$title" -f "$key" -q </dev/null
  ok "created ~/.ssh/id_ed25519_signing for $(uname -n)"
fi

if [ ! -f "$key.pub" ]; then
  warn "no signing key could be created — signing stays off on this machine"
  git config --global --unset-all commit.gpgsign 2>/dev/null || true
  return 0
fi

# --- git config, all of it machine-local ------------------------------------
# These land in ~/.gitconfig, below its include, so they override the shared
# config and leave the repo alone.
git config --global gpg.format ssh
git config --global user.signingkey "$key.pub"
git config --global commit.gpgsign true
git config --global gitbutler.signCommits true
git config --global gpg.ssh.allowedSignersFile "$signers"

# Migration: op-ssh-sign was this repo's signer on macOS. It needs the
# 1Password app running and can put a biometric prompt in front of a commit,
# which is not survivable in an agent session. A file key needs no program.
if git config --global --get gpg.ssh.program 2>/dev/null | grep -q 'op-ssh-sign'; then
  git config --global --unset-all gpg.ssh.program
  warn "dropped gpg.ssh.program (1Password) in favour of this machine's key"
fi

# --- allowed_signers, so local verification works ---------------------------
# Generated as "the tracked list of known machines" + "this machine", which is
# why a machine always trusts itself with no commit required. Without this file
# `git log --show-signature` cannot verify anything and only errors.
email=$(git config --get user.email 2>/dev/null || echo "$USER@$(uname -n)")
blob=$(cut -d' ' -f1-2 <"$key.pub")

{
  [ -f "$tracked_signers" ] && cat "$tracked_signers"
  # Skip if the tracked list already carries this machine, so the file has no
  # duplicate lines after the key has been committed.
  if ! { [ -f "$tracked_signers" ] && grep -qF "$blob" "$tracked_signers"; }; then
    printf '%s %s\n' "$email" "$blob"
  fi
} >"$signers"
ok "~/.ssh/allowed_signers built for local verification"

# --- does it actually sign? -------------------------------------------------
# Configuration that looks right and does not work is the failure this step
# exists to end, so sign a real commit in a throwaway repo with the agent
# deliberately removed from the environment.
probe=$(mktemp -d)
if git init -q "$probe" 2>/dev/null &&
   env -u SSH_AUTH_SOCK git -C "$probe" commit -q --allow-empty -m 'signing probe' 2>/dev/null; then
  case $(env -u SSH_AUTH_SOCK git -C "$probe" log --format='%G?' -1 2>/dev/null) in
    G) ok "signed and verified a test commit with no ssh-agent" ;;
    U) warn "signs, but the signature is untrusted — check ~/.ssh/allowed_signers" ;;
    *) warn "a commit was made but is not signed — check user.signingkey" ;;
  esac
else
  warn "could not sign a test commit — turning signing off so commits keep working"
  git config --global commit.gpgsign false
fi
rm -rf "$probe"

# --- GitHub ----------------------------------------------------------------
# Without the key registered as a *signing* key, GitHub shows every commit as
# Unverified however well it verifies locally. Authentication keys do not count
# for this, which is worth knowing: it is possible to have three keys on the
# account and still no way to verify a commit.
if ! has gh; then
  info "gh is not installed — register the key by hand:"
  info "  https://github.com/settings/ssh/new   (key type: Signing Key)"
  info "  $(cat "$key.pub")"
elif ! gh auth status >/dev/null 2>&1; then
  info "gh is not logged in — run 'gh auth login', then ./install.sh git-signing"
elif gh api user/ssh_signing_keys --jq '.[].key' 2>/dev/null | grep -qF "$blob"; then
  ok "already registered on GitHub as a signing key"
elif gh ssh-key add "$key.pub" --type signing --title "$title" >/dev/null 2>&1; then
  ok "registered on GitHub as a signing key: $title"
else
  # Almost always the missing scope. A token with only read:ssh_signing_key can
  # list keys, which is why the check above works and the add does not.
  warn "could not add the key to GitHub — the token is probably missing a scope"
  info "  gh auth refresh -s admin:ssh_signing_key && ./install.sh git-signing"
  info "or add it by hand at https://github.com/settings/ssh/new (type: Signing Key):"
  info "  $(cat "$key.pub")"
fi

# --- cross-machine verification --------------------------------------------
if [ -f "$tracked_signers" ] && grep -qF "$blob" "$tracked_signers"; then
  ok "this machine's key is in the tracked allowed_signers list"
else
  info "to let your other machines verify commits made here, add this line to"
  info "config/shared/.config/git/allowed_signers and commit it:"
  info "  $email $blob"
fi
