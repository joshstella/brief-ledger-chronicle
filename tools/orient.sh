#!/usr/bin/env bash
# tools/orient.sh [BRIEFS_DIR]
# Rung 0: the cheapest read of this repository. Answers three questions —
# what is in flight, what must not be broken, what this project values — in
# roughly 700 tokens, and points at the more expensive rungs for the rest.
#
# Run from the repository root. Writes to stdout. Never writes a tracked file:
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

BRIEFS_DIR="${1:-docs/briefs}"
STATE_DIR="docs/state"
AUTHORED="docs/orientation.md"
INSTALL_LOG="docs/install-log/install-log.md"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 1; }
ROOT="$(git rev-parse --show-toplevel)"

# ── How much to trust any of this ────────────────────────────────────────────
#
# Everything below is derived from local refs, so on a stale clone it is
# confidently wrong. #0003 has the concrete case on the record: three merged PRs
# and two deleted branches stayed invisible to a second machine until it fetched.
# Counting against the remote is the honest measure and costs one line.

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
echo "$line"
echo

# ── What is in flight ────────────────────────────────────────────────────────
#
# Two sources, because one of them structurally cannot reach the other's case. A
# ledger starts at blc-start-brief, which runs after a serial is already chosen,
# so work picked up but not yet filed is in no record at all. That is what
# docs/state/ is for. See docs/state/README.md.

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
  [ "$closed" -gt 0 ] && { echo; echo "$closed closed — full timeline in \`docs/chronicles/chronicle.md\`."; }
else
  echo "No \`$BRIEFS_DIR\` — nothing filed here yet."
fi
echo

echo "### Picked up, not yet filed"
echo
declared=0
if [ -d "$STATE_DIR" ]; then
  for f in "$STATE_DIR"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "README.md" ] && continue
    [ -s "$f" ] || continue
    who="$(basename "$f" .md)"
    # Nothing prunes this directory, so age is reported rather than enforced —
    # a declaration someone abandoned shows up as old instead of as truth.
    touched="$(git log -1 --format='%ad' --date=short -- "$f" 2>/dev/null || true)"
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
  created="$(awk '/^### Created/{f=1;next} /^###|^## /{f=0} f && /^ *- /{sub(/^ *- /,"");print}' "$INSTALL_LOG" | sort -u)"
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
  echo "No \`$INSTALL_LOG\` — this repo was not set up by the installer."
fi
if [ -f "docs/contracts/v1.1.md" ]; then
  echo
  echo "Contract v1.1 binds the briefs directory. \`tools/validate-briefs.sh\` is the gate."
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
  sed '1{/^# /d}' "$AUTHORED"
else
  echo "No \`$AUTHORED\` — nobody has written down what matters here."
  echo "It is the one part of this output a person has to author."
fi
echo
echo "---"
echo "Deeper: \`README.md\` · \`Manifesto.md\` · \`$BRIEFS_DIR/README.md\` · one brief · one ledger."
