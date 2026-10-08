#!/usr/bin/env bash
# tools/orient.sh [BRIEFS_DIR]
# Rung 0: the cheapest read of this repository. Answers three questions —
# what is in flight, what must not be broken, what this project values — in
# roughly 700 tokens, and points at the more expensive rungs for the rest.
#
# Runs from anywhere inside the work tree: it changes to the root before it reads anything
# (#0024). Writes to stdout. Never writes a tracked file:
# if this output is ever committed, the design has failed.
#
# Every section degrades to a stated absence rather than an error, because the
# first thing a fresh install has is none of these sources. Exit is zero unless
# this is not a git repository at all.
#
# Determinism is a requirement, not a nicety — two runs with no change to the
# repository produce identical bytes. That rules out wall-clock output, so ages
# below are whole days and everything else is an absolute date or a commit count.
set -euo pipefail

BRIEFS_DIR="${1:-docs/blc/briefs}"
# An explicit path is relative to the caller, as it is for every other shell tool, so it is
# made absolute here — before the `cd` below moves this script to the root (#0024). The
# default is deliberately not: it is relative to the root by definition, and anchoring it to
# the caller's directory is the defect this fixes. No `realpath`, which is not dependable on
# macOS, and no canonicalising, which nothing below needs.
if [ -n "${1:-}" ]; then
  case "$1" in /*) ;; *) BRIEFS_DIR="$PWD/$1" ;; esac
fi
# Every other path is a sibling of the briefs directory, so one argument moves them all. A
# briefs argument that left these at the default root would be the partial flexibility #0017
# names as worse than either alternative.
BLC_ROOT="$(dirname "$BRIEFS_DIR")"
STATE_DIR="$BLC_ROOT/state"
AUTHORED="$BLC_ROOT/orientation.md"
INSTALL_LOG="$BLC_ROOT/install-log/install-log.md"
CHRONICLE="$BLC_ROOT/chronicles/chronicle.md"
CONTRACT="$BLC_ROOT/contracts/v1.5.md"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 1; }
ROOT="$(git rev-parse --show-toplevel)"
# Every path this script reads is relative, and until now it resolved them against whatever
# directory the caller stood in. From a subdirectory that made orient report a filed record as
# absent — and say so as a claim about the project, not about a path — while still exiting 0.
# Its siblings fail loudly in the same place; orient degrades absences into statements by
# design (#0021), so it had no way to fail at all. One `cd` corrects the record paths, the
# self-host check and the footer (#0024).
cd "$ROOT"

# ── How much to trust any of this ────────────────────────────────────────────
#
# Everything below is derived from local refs, so on a stale clone it is
# confidently wrong. #0003 has the concrete case on the record: three merged PRs
# and two deleted branches stayed invisible to a second machine until it fetched.
# Counting against the remote is the honest measure and costs one line.
#
# The branch's own upstream is not enough. It answers "is this branch current", and the
# record the rest of this output reads lives on the trunk. A pushed branch on a stale base
# reads `0 behind / 0 ahead`, and a branch with no upstream makes no comparison at all; #0021
# has both cases, one of which cost a whole branch. So the checkout is also counted against
# the trunk, read offline from `origin/HEAD`, which a clone sets. Still local refs: the trunk
# count is as fresh as the last fetch, and the line claims nothing more.

echo "# Orientation"
echo
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
line="on \`$branch\`"
upstream="$(git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null || true)"
if [ -n "$upstream" ]; then
  behind="$(git rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)"
  ahead="$(git rev-list --count "$upstream..HEAD" 2>/dev/null || echo 0)"
  line="$line · $behind behind / $ahead ahead of \`$upstream\`"
  [ "$behind" -gt 0 ] && line="$line — **fetch before trusting this**"
else
  line="$line · no upstream — this is a local-only view"
fi
trunk="$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"
if [ -n "$trunk" ] && [ "$trunk" != "$upstream" ]; then
  # Only "behind" is printed. Commits ahead of the trunk are this branch's own work, which
  # says nothing about whether the record below is current.
  trunk_behind="$(git rev-list --count "HEAD..$trunk" 2>/dev/null || echo 0)"
  line="$line · $trunk_behind behind \`$trunk\`"
  [ "$trunk_behind" -gt 0 ] && line="$line — **the record on \`$trunk\` is newer**"
elif [ -z "$trunk" ] && git remote get-url origin >/dev/null 2>&1; then
  # A repository made with `git init` and a remote added later has no `origin/HEAD`. Saying
  # nothing would read as "nothing to compare", which is not the same thing.
  line="$line · trunk unknown (set it with \`git remote set-head origin --auto\`)"
fi
echo "$line"
echo

# ── What is in flight ────────────────────────────────────────────────────────
#
# Two sources, because one of them structurally cannot reach the other's case. A
# ledger starts at blc-start-brief, which runs after a serial is already chosen,
# so work picked up but not yet filed is in no record at all. That is what
# docs/blc/state/ is for. See docs/blc/state/README.md.

echo "## In flight"
echo
if [ -d "$BRIEFS_DIR" ] && [ -x "$ROOT/tools/list-briefs.sh" ]; then
  table="$(bash "$ROOT/tools/list-briefs.sh" "$BRIEFS_DIR")"
  # Rung 0 filters where the chronicle does not. #0006 settled that the chronicle
  # table stays complete; this is the same generator read by a different consumer
  # with a different rule. Unfiltered it costs ~35 tokens per brief forever, which
  # breaks the flat rung cost somewhere around twenty briefs.
  # $2 is the serial cell; list-briefs emits a row of dashes for an empty tree, and
  # that row has no status to filter on.
  open_rows="$(printf '%s\n' "$table" | awk -F'|' 'NR>2 && $2 ~ /#/ && $4 !~ /done|skipped/ {print}')"
  closed="$(printf '%s\n' "$table" | awk -F'|' 'NR>2 && $2 ~ /#/ && $4 ~ /done|skipped/' | grep -c . || true)"
  if [ -n "$open_rows" ]; then
    printf '%s\n' "| serial | title | status |"
    printf '%s\n' "|---|---|---|"
    printf '%s\n' "$open_rows" | awk -F'|' '{printf "|%s|%s|%s|\n", $2, $3, $4}'
  else
    echo "Nothing open."
  fi
  # The count is what keeps the omission honest: a reader is told history exists
  # and where it lives, rather than shown a table that silently stops.
  [ "$closed" -gt 0 ] && { echo; echo "$closed closed — full timeline in \`$CHRONICLE\`."; }
else
  echo "No \`$BRIEFS_DIR\` — nothing filed here yet."
fi
echo

echo "### Picked up, not yet filed"
echo
declared=0
# A declaration's age follows renames and skips the ignore list, as the brief dates do. #0017
# moved this directory, and a plain `git log` would have aged every declaration to the move.
# Without the lib the age is the plain log's, which is a worse answer and still an answer.
TOUCH_LIB="$ROOT/tools/lib/touch-log.sh"
if [ -r "$TOUCH_LIB" ]; then
  # shellcheck source=/dev/null
  . "$TOUCH_LIB"
  SKIP="$(blc_touch_skip "$BLC_ROOT/ignore-revs")"
  RENAMES="$(blc_touch_renames)"
fi
if [ -d "$STATE_DIR" ]; then
  for f in "$STATE_DIR"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "README.md" ] && continue
    [ -s "$f" ] || continue
    who="$(basename "$f" .md)"
    # Nothing prunes this directory, so age is reported rather than enforced —
    # a declaration someone abandoned shows up as old instead of as truth.
    if [ -r "$TOUCH_LIB" ]; then
      touched="$(blc_touch_log "$SKIP" "$RENAMES" "$f" | sed -n '1s/^[^ ]* \(.\{10\}\).*/\1/p')"
    else
      touched="$(git log -1 --format='%ad' --date=short -- "$f" 2>/dev/null || true)"
    fi
    echo "- **$who** (last written ${touched:-uncommitted})"
    sed -n 's/^## /  · /p' "$f"
    declared=$((declared + 1))
  done
fi
[ "$declared" -eq 0 ] && echo "Nobody has declared unfiled work."
echo

# ── What must not be broken ──────────────────────────────────────────────────
#
# Derived from the install log, not from install.sh. The log is the installer's
# own append-only record of what it wrote into *this* repository, so it is
# present in every target — where install.sh is not — and it cannot drift from
# the installer the way a restatement here would.

echo "## Off-limits"
echo
if [ -f "$INSTALL_LOG" ]; then
  # The log is replayed, not skimmed. Each run has three sections that change what exists:
  # Created, Removed, and Moved. Reading only Created listed paths a later run had pruned or
  # moved, which an adopting repository was then told to keep off (#0021). Within one run,
  # the installer moves the old layout first (Step 3a), then prunes, then places, so a run is
  # applied in that order and not in the order its sections are written.
  #
  # The disk is never read. A path the install wrote and a person deleted by hand stays on
  # the list, because that is the one a reader most needs to see (#0021 decision 1).
  #
  # A move or a drop in a run takes the whole old tree off the list, not only the file. The
  # old layout put each tree directly under docs/, so the tree is the path's first two
  # segments, and the upgrade deletes every tree it moves from. Old runs listed the trees
  # themselves (`docs/contracts`), and no file entry would ever remove those. A path that was
  # on the list and moved comes back at its new place. The text after a path in parentheses
  # is the log's note, not part of the path.
  created="$(awk -v arrow=' → ' '
    function flush(   i, n, seg, root, k, gone, back) {
      for (i = 1; i <= nm; i++) {
        if (mdst[i] != "" && (msrc[i] in live)) back[mdst[i]] = 1
        n = split(msrc[i], seg, "/")
        root = (n >= 2) ? seg[1] "/" seg[2] : msrc[i]
        for (k in live) if (k == root || index(k, root "/") == 1) gone[k] = 1
      }
      for (k in gone) delete live[k]
      for (k in back) live[k] = 1
      for (i = 1; i <= nr; i++) delete live[rem[i]]
      for (i = 1; i <= nc; i++) live[cre[i]] = 1
      nm = 0; nr = 0; nc = 0
    }
    /^## /            { flush(); sect = ""; next }
    /^### Created/    { sect = "c"; next }
    /^### Removed/    { sect = "r"; next }
    /^### Moved/      { sect = "m"; next }
    /^###/            { sect = ""; next }
    sect != "" && /^ *- / {
      line = $0; sub(/^ *- /, "", line)
      if (sect == "c") { cre[++nc] = line; next }
      if (sect == "r") { rem[++nr] = line; next }
      a = index(line, arrow)
      if (a > 0) {
        src = substr(line, 1, a - 1)
        dst = substr(line, a + length(arrow))
      } else {
        src = line; dst = ""
      }
      sub(/ \([^)]*\)$/, "", src); sub(/ \([^)]*\)$/, "", dst)
      ++nm; msrc[nm] = src; mdst[nm] = dst
    }
    END { flush(); for (k in live) print k }
  ' "$INSTALL_LOG" | LC_ALL=C sort -u)"
  # Drop anything whose parent directory is already listed: the log records both the
  # scaffolded directory and the files placed inside it, and naming both spends tokens
  # to say one thing.
  owned="$(printf '%s\n' "$created" | awk 'NR==FNR{seen[$0];next} { p=$0; keep=1; while (sub(/\/[^\/]*$/,"",p)) if (p in seen) keep=0; if (keep) print }' <(printf '%s\n' "$created") -)"
  if [ -n "$owned" ]; then
    # Strictly what the log says: these are paths the installer wrote. It does not
    # record an ownership class, so this does not claim one — AGENTS.md and .gitignore
    # are created once and then belong to the project, and inferring otherwise here
    # would mean restating install.sh's rules, which is the drift this brief argues
    # against. Treat the list as "changed by an install", not as "do not touch".
    echo "Paths this repo's installer wrote (per \`$INSTALL_LOG\`):"
    printf '%s\n' "$owned" | sed 's/^/- `/;s/$/`/'
  else
    echo "The install log records no created paths."
  fi
else
  # Two repositories have no install log, and they are not the same thing. One has never
  # been installed into. The other is the toolkit's own checkout, which reaches its skills
  # through committed links instead of an install, because the source is not a target
  # (#0019). Saying "not set up by the installer" there reads as a missing step and sends a
  # reader to run one, which the installer refuses.
  #
  # A real target never arrives here: an install writes the log. So the only question this
  # branch has to answer is which of those two it is.
  self_hosted=false
  for host_skills in .cursor/skills .claude/skills/*; do
    [ -L "$host_skills" ] || continue
    # The link is followed rather than read, because its text is relative and a reader of
    # `../skills` cannot tell which directory that lands in.
    resolved="$(cd -P "$host_skills" 2>/dev/null && pwd)" || continue
    case "$resolved" in
      "$ROOT/skills"|"$ROOT/skills/"*) self_hosted=true; break ;;
    esac
  done
  if [ "$self_hosted" = true ]; then
    echo "No \`$INSTALL_LOG\` — this is the toolkit source, not a target."
    echo "It runs its own skills through committed links into \`skills/\`."
  else
    echo "No \`$INSTALL_LOG\` — this repo was not set up by the installer."
  fi
fi
if [ -f "$CONTRACT" ]; then
  echo
  echo "Contract v1.5 binds the briefs directory. \`tools/validate-briefs.sh\` is the gate."
fi
echo

# ── What this project values ─────────────────────────────────────────────────
#
# The only authored part. It is capped rather than trusted: a cap makes curation
# self-enforcing, because a ninth principle means arguing one of eight out. The
# cap governs quantity and cannot govern quality — nothing here says the eight
# are the right eight.

echo "## What this project values"
echo
if [ -f "$AUTHORED" ]; then
  # The `;` before the `}` is required by POSIX and optional in GNU sed. Without it, BSD sed —
  # which macOS ships — rejects the script, and `set -e` above turns that into exit 1 after the
  # whole report has already printed. Reported from macOS on 2026-10-08.
  sed '1{/^# /d;}' "$AUTHORED"
else
  echo "No \`$AUTHORED\` — nobody has written down what matters here."
  echo "It is the one part of this output a person has to author."
fi
echo
echo "---"
# The installer does not ship Manifesto.md, so a target has one only if it wrote its own. A
# pointer to a missing file sends the reader looking for nothing.
MANIFESTO=""
[ -f Manifesto.md ] && MANIFESTO=" · \`Manifesto.md\`"
echo "Deeper: \`README.md\`$MANIFESTO · \`$BRIEFS_DIR/README.md\` · one brief · one ledger."
