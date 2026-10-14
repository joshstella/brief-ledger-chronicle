# blic-prompt.bash — the shell prompt segment. Source this; do not run it.
#
#   . /path/to/experiments/blic/p5-ambient/blic-prompt.bash
#   PS1='$(blic_prompt) \w \$ '
#
# The whole point of this file is that it forks nothing on a normal prompt. No `git`, no
# `stat`, no `id`, no `cat`, no subshell. Everything below is a bash builtin against an
# already-rendered string. Measured at ~0.1ms added per prompt; see bench.sh.
#
# It forks exactly twice per BLIC_TTL seconds, to spawn a detached refresh, and that refresh
# is what pays read.sh's ~3.5s where nobody is waiting on it.

# Resolved into a private name, not back into BLIC_P5_DIR. `BLIC_P5_DIR=x . blic-prompt.bash`
# is an assignment prefix on a special builtin, and bash reverts that name when the builtin
# returns — including an assignment the sourced file made to it. Writing the resolved path to
# the same name therefore loses it, and the loss only shows up later, in the refresh spawn, in
# a shell with `set -u`, where it kills the subshell and the line never appears.
_BLIC_DIR="${BLIC_P5_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
BLIC_TTL="${BLIC_TTL:-20}"

# Repo root by walking up for `.git`, because `git rev-parse --show-toplevel` is a process
# and this function runs before every prompt a person ever sees. Memoised on $PWD: the walk
# only repeats when you change directory.
_blic_locate() {
  _blic_pwd="$PWD"
  _blic_cache=""
  local d="$PWD" base key
  while [[ -n "$d" ]]; do
    [[ -e "$d/.git" ]] && break
    d="${d%/*}"
  done
  [[ -n "$d" && -e "$d/.git" ]] || return 0
  # Only speak up in a repository that has the instrument. Elsewhere the segment is empty,
  # which is the correct behaviour for a prompt: silence costs nothing and noise costs trust.
  [[ -r "$d/experiments/blic/read.sh" ]] || return 0
  _blic_repo="$d"
  base="${BLIC_CACHE_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/blic-$UID}"
  key="${d//[^A-Za-z0-9]/-}"
  _blic_cache="$base/${key#-}"
}

# At most one spawn per TTL per shell, tracked in a variable rather than on disk. Two shells
# in the same repo may both spawn; the refresher's lock makes the second one exit immediately.
_blic_spawn() {
  (( EPOCHSECONDS - ${_blic_spawned:-0} < BLIC_TTL )) && return 0
  _blic_spawned=$EPOCHSECONDS
  ( BLIC_REPO="$_blic_repo" "$_BLIC_DIR/blic-refresh.sh" --auto >/dev/null 2>&1 & ) 2>/dev/null
}

blic_prompt() {
  [[ "$PWD" == "${_blic_pwd-}" ]] || _blic_locate
  [[ -n "${_blic_cache-}" ]] || return 0

  local gen line age
  # `read` with a redirect is a builtin reading a file. No `cat`, no command substitution,
  # and therefore no fork and no subshell teardown on the prompt path.
  #
  # The `2>/dev/null` goes BEFORE the input redirect, not after. Redirections apply left to
  # right, so with the obvious order the failed open reports to the real stderr and a repo
  # with no cache yet prints a bash error above every prompt the person types.
  if ! read -r gen line 2>/dev/null < "$_blic_cache/line"; then
    _blic_spawn
    return 0
  fi
  age=$(( EPOCHSECONDS - gen ))
  (( age > BLIC_TTL )) && _blic_spawn
  # A line nobody has refreshed in minutes is marked rather than hidden. `docs/blc/briefs`
  # says a stale status line is worse than no line because a cheap scan trusts it; a cheap
  # scan of this field should be able to see that it has stopped being cheap to trust.
  (( age > BLIC_TTL * 10 )) && line="$line ?"
  printf '%s' "$line"
}
