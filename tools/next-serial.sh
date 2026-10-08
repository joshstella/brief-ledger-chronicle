#!/usr/bin/env bash
# tools/next-serial.sh [briefs-dir]
# Print the next free brief serial, zero-padded to four digits. Writes nothing.
#
# `blc-create-brief` used to answer this by listing the local briefs directory. That is the
# whole view on one machine and only part of it on two. On 2026-10-07 two contributors filed
# two briefs as #0018: the first filed at 02:46 and pushed to a branch, because pushing to
# the trunk needed an access level they did not have; the second filed at 04:06 against a
# trunk that still ended at 0017. Neither read a stale directory. Both read a true one that
# did not contain the other.
#
# So this program reads the remote as well, by listing the briefs directory on every `origin`
# branch. A serial filed on a branch is a serial taken, whether or not it has merged.
#
# This NARROWS the window. It does not close the race, and nothing here should be read as
# closing it. Two checkouts can fetch the same `origin` within a second of each other, both
# see 0033, and both answer 0034 — because answering is not claiming, and this program
# publishes nothing. Closing the race means reserving the number where the other reader will
# look, before they look. That needs a push at filing time, and the incident is partly about
# a contributor who could not push. The Contract states the limit rather than hiding it.
set -euo pipefail

BRIEFS_REL="${1:-docs/blc/briefs}"

# Every unread source, collected rather than printed as it happens. A serial could be hiding
# behind any of them, and the caller needs to know that before acting on the number — one
# summary after the answer is easier to act on than warnings interleaved with it.
UNREAD=""
note_unread() { UNREAD="$UNREAD  - $1
"; }

# usage: serials_from <lines> — the four-digit prefixes of entries that have one.
#
# Anchored at the start of the entry name and followed by a hyphen, so `_drafts`, `README.md`
# and a stray `2026-notes` contribute nothing. Entries without the prefix are not errors; the
# layout has always allowed them.
serials_from() {
  printf '%s\n' "$1" \
    | sed -n 's|^.*/\([0-9][0-9][0-9][0-9]\)-[^/]*/\{0,1\}$|\1|p
              s|^\([0-9][0-9][0-9][0-9]\)-[^/]*/\{0,1\}$|\1|p'
}

HIGHEST=0
# usage: raise <serials> — moves the running maximum, never lowers it.
#
# The maximum, not the count. A registry with a gap in it is BRIEFS-8's problem to report,
# and counting would hand back a serial that something already used — which is this program
# causing the exact collision it exists to prevent.
raise() {
  local s
  for s in $1; do
    # Base 10 forced. A serial like 0008 is a valid octal literal and 0009 is not, so the
    # default base would make arithmetic fail on one brief in ten.
    s=$((10#$s))
    [ "$s" -gt "$HIGHEST" ] && HIGHEST="$s"
  done
  # Explicit, because the loop's last statement is an AND-list that returns 1 whenever the
  # final serial is not a new maximum. Under `set -e` that would end the program partway
  # through the scan, on the common input where the highest serial is not the last one read.
  return 0
}

# ── The local directory ──────────────────────────────────────────────────────

if [ -d "$BRIEFS_REL" ]; then
  # Directories only. The unit of a brief is a folder (BRIEFS-4), so a stray `0033-notes.md`
  # beside them is not a filed serial. Counting it would raise the maximum and skip a real
  # number, which BRIEFS-8 then reports as a gap in a registry that has none.
  raise "$(serials_from "$(find "$BRIEFS_REL" -maxdepth 1 -mindepth 1 -type d 2>/dev/null || true)")"
else
  # The one condition this program refuses to answer through, and the only place it departs
  # from reporting rather than gating. Every other unread source costs accuracy; this one
  # costs correctness. A tree whose briefs live somewhere else — the pre-#0017 `docs/briefs/`
  # layout, or a caller run from the wrong directory — looks exactly like a tree with no
  # briefs at all, and the answer for both is 0001. Handing 0001 to a registry that already
  # holds thirty briefs is the collision this program was written to prevent, caused by the
  # program itself. The warning would not save a caller reading stdout.
  #
  # `tools/validate-briefs.sh` refuses the same input for the same reason.
  echo "next-serial: not a directory: $BRIEFS_REL" >&2
  echo "  Pass the briefs directory, or run blc-init-briefs if this project has none yet." >&2
  echo "  Refusing rather than answering 0001: a registry stored elsewhere looks identical" >&2
  echo "  to an empty one from here, and 0001 would collide with every brief already filed." >&2
  exit 2
fi

# ── Every origin branch ──────────────────────────────────────────────────────

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  note_unread "not inside a git repository, so no branch was read"
elif ! git remote get-url origin >/dev/null 2>&1; then
  # A repository with no `origin` is a solo checkout, and the local directory is the whole
  # truth. Saying so would warn on every run of a setup that has nothing wrong with it, and
  # a warning printed every time is one nobody reads when it matters.
  :
else
  # Fetched, not trusted from the last fetch. Remote-tracking refs are a snapshot of whenever
  # someone last ran `git fetch`, and the gap between filings in the incident was 80 minutes.
  # A stale snapshot is the failure mode this program exists to remove, reappearing one level
  # down.
  if ! git fetch --quiet --prune origin >/dev/null 2>&1; then
    note_unread "\`git fetch origin\` did not work, so branches may be missing or stale"
  fi

  branches="$(git for-each-ref --format='%(refname)' refs/remotes/origin/ 2>/dev/null || true)"
  if [ -z "$branches" ]; then
    note_unread "\`origin\` has no branches this checkout knows about"
  fi

  for ref in $branches; do
    # origin/HEAD is a symbolic ref to another branch in this same list. Listing it would
    # read one branch twice, which costs a round of work and cannot change the answer.
    [ "$ref" = "refs/remotes/origin/HEAD" ] && continue

    # `-d` for the same reason as the local scan: trees only, because a brief is a folder.
    # Non-recursive and scoped to the one path — the names are all at this level, and `-r`
    # would walk every file in every brief on every branch to learn nothing more.
    if entries="$(git ls-tree -d --name-only "$ref" "$BRIEFS_REL/" 2>/dev/null)"; then
      raise "$(serials_from "$entries")"
    else
      # A branch that will not list is the dangerous case: it is exactly where an unmerged
      # filing lives. Skipping it quietly is how this program would hand back a taken number
      # while looking like it had checked.
      note_unread "could not list \`$BRIEFS_REL\` on \`${ref#refs/remotes/}\`"
    fi
  done
fi

# ── The answer ───────────────────────────────────────────────────────────────

ANSWER="$(printf '%04d' "$((HIGHEST + 1))")"
printf '%s\n' "$ANSWER"

# Exit 0 either way. A partial read still produces the best number available, and refusing to
# answer would stop a contributor filing offline — which is most of them, most of the time.
# This project reports rather than gates, and the report is the part that must not be missed:
# it goes to stderr so a caller capturing stdout gets the number and a person sees the gap.
if [ -n "$UNREAD" ]; then
  echo "next-serial: answered $ANSWER without reading everything." >&2
  printf '%s' "$UNREAD" >&2
  echo "  A serial claimed in an unread place would collide with this answer." >&2
fi
