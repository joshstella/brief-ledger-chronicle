#!/usr/bin/env sh
# tools/check-architecture.sh [DOC]
# Check that every citation in the architecture document still points at code that exists.
# DOC defaults to docs/architecture/README.md. Writes a report to stdout.
#
# The document is written by an agent reading a codebase, and nothing can prove such a document
# is right. What this proves is narrower and is the reason the document is worth committing at
# all: every claim in it names the code that supports it, and that code is still there. A
# committed architecture document without this check goes quietly wrong. With it, it goes
# noisily wrong (#0029).
#
# A citation is an HTML comment at the end of the line making the claim, so it is invisible in
# rendered Markdown and trivially greppable — the same trick as the chronicle's closed-through
# marker:
#
#   The router owns request dispatch. <!-- cite: src/router.ts :: export class Router -->
#   Nothing else reads the socket.    <!-- cite: src/net/socket.ts -->
#
# The anchor is literal text, matched with `grep -F`, not a line number. Any edit above a cited
# line shifts every citation below it, so a line-based check goes red on refactors that changed
# nothing it cares about — and a check that is noisy on every refactor gets switched off, which
# is worse than no check. An anchor fails when the thing it names is actually gone.
#
# The anchor is optional. With none, the citation claims only that the file exists.
#
# **This reports, it does not gate.** A rotted citation means the document is behind the code.
# That is a thing to know, not a reason to stop a merge (#0029). Exit status is 0 whenever the
# check ran, whatever it found. It is 1 only when the check could not run at all: no document,
# or a document that cannot be read.
set -eu

DOC="${1:-docs/architecture/README.md}"

# An explicit path is relative to the caller, as it is for every other shell tool, so it is made
# absolute before the `cd` below (#0024). The default is deliberately not: it is relative to the
# root by definition.
if [ -n "${1:-}" ]; then
  case "$1" in /*) ;; *) DOC="$PWD/$1" ;; esac
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "check-architecture: not inside a git work tree" >&2
  exit 1
}
# Every cited path is relative to the repository root, so the check reads the same from any
# directory. This is the #0024 defect, not repeated here.
cd "$ROOT"

[ -r "$DOC" ] || {
  echo "check-architecture: cannot read $DOC" >&2
  echo "  Write it with the blc-architecture skill, or name another document." >&2
  exit 1
}

TOTAL=0
ROTTED=0

# `grep -n -o` gives `LINE:<!-- cite: … -->`, one per citation, so a line making two claims is
# two findings and keeps its line number for both.
CITES="$(grep -n -o '<!-- *cite:[^>]*-->' "$DOC" || true)"

if [ -z "$CITES" ]; then
  echo "architecture check — ${DOC#"$ROOT"/}"
  echo
  echo "  No citations. Nothing in this document can be checked, so nothing here says it is"
  echo "  still true. Every claim should carry <!-- cite: <path> :: <anchor> -->."
  exit 0
fi

REPORT=""
# A literal newline, because this has to work where `echo -e` does not.
NL='
'

printf '%s\n' "$CITES" | {
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line="${hit%%:*}"
    body="${hit#*:}"
    # Strip the comment wrapper, then the label, then the spaces each leaves behind.
    body="${body#*cite:}"
    body="${body%-->}"
    body="${body#"${body%%[! ]*}"}"
    body="${body%"${body##*[! ]}"}"

    case "$body" in
      *" :: "*) path="${body%% :: *}"; anchor="${body#* :: }" ;;
      *) path="$body"; anchor="" ;;
    esac
    path="${path%"${path##*[! ]}"}"
    anchor="${anchor#"${anchor%%[! ]*}"}"
    anchor="${anchor%"${anchor##*[! ]}"}"

    TOTAL=$((TOTAL + 1))
    if [ -z "$path" ]; then
      REPORT="$REPORT  line $line  (empty) — the citation names no path$NL"
      ROTTED=$((ROTTED + 1))
    elif [ ! -f "$path" ]; then
      REPORT="$REPORT  line $line  $path — file not found$NL"
      ROTTED=$((ROTTED + 1))
    elif [ -n "$anchor" ] && ! grep -qF -- "$anchor" "$path"; then
      REPORT="$REPORT  line $line  $path :: $anchor — anchor not found$NL"
      ROTTED=$((ROTTED + 1))
    fi
  done

  echo "architecture check — ${DOC#"$ROOT"/}"
  echo
  if [ "$ROTTED" -eq 0 ]; then
    echo "  $TOTAL citation(s), all resolve."
  else
    echo "  $TOTAL citation(s), $((TOTAL - ROTTED)) resolve, $ROTTED rotted."
    echo
    printf '%s' "$REPORT"
    echo
    echo "  A rotted citation means the document is behind the code. Re-run the"
    echo "  blc-architecture skill, or correct the citation by hand."
  fi
}
