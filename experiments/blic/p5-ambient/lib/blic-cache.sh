#!/usr/bin/env bash
# lib/blic-cache.sh — cache locations and the digest format, shared by every surface here.
#
# Sourced by blic-refresh.sh, blic-statusline.sh and bin/blic. The prompt fast path does NOT
# source this: it reads the rendered line directly, because sourcing anything is already more
# work than printing a cached string.
#
# Nothing in p5 writes a record. The cache holds a rendering of the record, outside the repo,
# and losing it costs one refresh.

# The cache is runtime state, not project state. XDG_RUNTIME_DIR when the system gives us one,
# /tmp otherwise. Never the repo and never $HOME: an install that litters either is an install
# a person cannot uninstall by deleting one directory.
blic_cache_dir() {
  local repo="$1" base key
  base="${BLIC_CACHE_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/blic-$(id -u)}"
  # One cache per checkout. Two worktrees of the same repo hold different branches and
  # therefore different records, and sharing a cache would make each one lie to the other.
  key="$(printf '%s' "$repo" | tr -c 'A-Za-z0-9' '-')"
  printf '%s/%s' "$base" "${key#-}"
}

# Where read.sh lives relative to this prototype. Resolved from the repo root so the surfaces
# work from any subdirectory.
blic_reader() { printf '%s/experiments/blic/read.sh' "$1"; }
blic_peer()   { printf '%s/experiments/blic/peer-events.sh' "$1"; }
