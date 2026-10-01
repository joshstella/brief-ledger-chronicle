#!/usr/bin/env bash
# Print which forge hosts this repository's remote: `github` or `gitlab`.
#
# Usage: detect-forge.sh [remote]     (default: origin, or the only remote when there is no origin)
#
# Exit 0 and print the forge when exactly one CLI accepts the remote's host. Exit 1, with
# nothing on stdout and the reason on stderr, when neither does or both do. Exit 2 when the
# question cannot be asked: not inside a git repository, or no such remote.
#
# Detected, not configured, so there is no setting to keep in sync. Skills run this program
# rather than describe detection in prose, because a second detector written as instructions
# to an agent is a detector nothing checks.
#
# Matched by host, not by URL shape. A self-hosted GitLab has no name to recognise, and with
# both CLIs installed, which one is present says nothing about the remote. `auth status
# --hostname` asks the server, so an expired token, no network and no account all read as no
# match, and the caller says it did not check instead of guessing. Each probe is a round trip;
# callers ask once.
#
# Both CLIs are asked even when the first accepts the host. A host both accept is ambiguous,
# and picking one would be the guess this program exists to replace.
#
# An SSH host alias (`git@work:org/repo.git`) is not resolved, so it matches nothing and the
# caller says it did not check.

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  printf 'error: not inside a git repository\n' >&2
  exit 2
fi

# With no argument, a repository with no origin and exactly one remote uses that remote: it can
# mean nothing else. With two or more, choosing one would be a guess. A remote named on the
# command line is never replaced.
REMOTE="${1:-origin}"
if [ -z "${1:-}" ] && ! git remote get-url origin >/dev/null 2>&1; then
  remotes="$(git remote)"
  case "$remotes" in
    ""|*$'\n'*) ;;
    *) REMOTE="$remotes" ;;
  esac
fi

if ! url="$(git remote get-url "$REMOTE" 2>/dev/null)"; then
  printf 'error: no remote named %s\n' "$REMOTE" >&2
  exit 2
fi

# The host of a remote URL, lowercased, or return 1 for a remote with no host: a local path
# or a file:// URL.
remote_host() {
  local u="$1"
  case "$u" in
    *://*)
      u="${u#*://}"
      u="${u%%/*}"
      u="${u##*@}"
      u="${u%%:*}" ;;
    /*|./*|../*) return 1 ;;
    *:*)
      u="${u%%:*}"
      u="${u##*@}" ;;
    *) return 1 ;;
  esac
  [ -n "$u" ] || return 1
  printf '%s' "$u" | tr '[:upper:]' '[:lower:]'
}

if ! host="$(remote_host "$url")"; then
  printf 'no forge: remote %s (%s) has no host\n' "$REMOTE" "$url" >&2
  exit 1
fi

# usage: probe <cli>; prints `accepts`, `rejects` or `not installed`. A rejection may mean no
# login, an expired token or no network; the probe cannot tell which.
probe() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'not installed'
  elif "$1" auth status --hostname "$host" </dev/null >/dev/null 2>&1; then
    printf 'accepts'
  else
    printf 'rejects'
  fi
}

gh_says="$(probe gh)"
glab_says="$(probe glab)"

case "$gh_says $glab_says" in
  "accepts accepts")
    printf 'no forge: both gh and glab accept %s\n' "$host" >&2
    exit 1 ;;
  "accepts "*) printf 'github\n' ;;
  *" accepts") printf 'gitlab\n' ;;
  *)
    printf 'no forge: neither CLI accepts %s (gh: %s, glab: %s)\n' \
      "$host" "${gh_says/rejects/did not accept}" "${glab_says/rejects/did not accept}" >&2
    exit 1 ;;
esac
