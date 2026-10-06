#!/usr/bin/env bash
# tools/stale-branches.sh [--tsv]
# Classify every local branch against the trunk. Writes nothing — not a ref, not a file.
#
#   default  a report for a person: the branches proven stale and the test that proved
#            each one, then the branches no test proved, with the commits they carry
#            that the trunk does not
#   --tsv    the same classification, one branch per line, tab separated:
#            <stale|unproven> <branch> <proof> <tip>
#
# A branch is proven stale only when one of three tests passes. The order is the order of
# strength, and the first to pass wins:
#
#   ancestor   `git merge-base --is-ancestor` — proof for a merge commit or a fast-forward.
#              A squash merge never passes it, and this toolkit merges by squash.
#   pr         the tip equals the head of a pull request that merged INTO THE TRUNK. Both
#              halves matter. A branch-name match is not proof: on 2026-10-05 a name match
#              passed three branches it had not proved, each with a commit pushed after its
#              PR merged. And a merged state is not proof either — a PR merged into a
#              release branch or another feature branch is merged somewhere that is not
#              here.
#   tree       merging the branch into the trunk gives the trunk's own tree. Needs no forge.
#              It can fail for a branch that is genuinely stale; it cannot pass for one that
#              is not. Useless across a large rename: every branch older than the #0017 move
#              to `docs/blc/` carries the old paths, so merging it adds them back and the
#              tree differs. On 2026-10-05 it proved none of the five it was asked about.
#
# What no test proves is reported as not proven, with its commits. This program never prints
# "merged" for a branch it cannot prove, because that sentence is what made the 2026-10-05
# name match look safe enough to act on.
#
# A test that cannot run says so. `pr` needs a forge and `tree` needs git 2.38, and a
# classification resting on two tests while claiming three is the quiet partial answer #0024
# was about. Both absences are printed.
set -euo pipefail

TSV=false
DELETE=false
TARGETS=()
case "${1:-}" in
  --tsv) TSV=true ;;
  --delete)
    DELETE=true
    shift
    TARGETS=("$@")
    # No names means no deletion. A bare `--delete` that removed everything currently proven
    # would make the dangerous reading of this program the shortest one to type, and would
    # delete against a classification nobody had read.
    if [ "${#TARGETS[@]}" -eq 0 ]; then
      echo "stale-branches: --delete needs at least one branch name." >&2
      echo "  Run with no arguments to see what is proven stale, then name what to delete." >&2
      exit 2
    fi ;;
  "") ;;
  *)
    echo "stale-branches: unknown argument \`$1\`." >&2
    exit 2 ;;
esac

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not inside a git repo." >&2; exit 2; }
cd "$(git rev-parse --show-toplevel)"

# Whichever trunk is further along, and the caller is told which. Neither one is right on its
# own. `origin/main` is the shared truth and goes stale between fetches. Local `main` can hold
# a commit nobody has pushed — which is not hypothetical: on 2026-10-06 an unpushed commit on
# local `main` made the first run of this program report a branch as carrying work the trunk
# already had. Comparing against the behind one is safe for deletion and wrong in the report,
# and a person acts on the report.
#
# A local trunk wins only when it is a descendant of the remote one. Diverged trunks are a
# different problem, and `origin/main` is the conservative answer to it.
TRUNK=""
REMOTE_TRUNK=""
LOCAL_TRUNK=""
if REMOTE_TRUNK="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"; then
  :
elif git rev-parse --verify --quiet refs/remotes/origin/main >/dev/null; then
  REMOTE_TRUNK="origin/main"
fi
if [ -n "$REMOTE_TRUNK" ]; then
  candidate="${REMOTE_TRUNK#origin/}"
  git rev-parse --verify --quiet "refs/heads/$candidate" >/dev/null && LOCAL_TRUNK="$candidate"
elif git rev-parse --verify --quiet refs/heads/main >/dev/null; then
  LOCAL_TRUNK="main"
fi

TRUNK_NOTE=""
if [ -n "$REMOTE_TRUNK" ] && [ -n "$LOCAL_TRUNK" ]; then
  if git merge-base --is-ancestor "$REMOTE_TRUNK" "$LOCAL_TRUNK" 2>/dev/null; then
    TRUNK="$LOCAL_TRUNK"
    ahead="$(git rev-list --count "$REMOTE_TRUNK..$LOCAL_TRUNK")"
    [ "$ahead" -gt 0 ] && TRUNK_NOTE="$ahead commit(s) ahead of \`$REMOTE_TRUNK\`, not yet pushed"
  else
    TRUNK="$REMOTE_TRUNK"
    git merge-base --is-ancestor "$LOCAL_TRUNK" "$REMOTE_TRUNK" 2>/dev/null \
      || TRUNK_NOTE="\`$LOCAL_TRUNK\` has diverged from it and was not used"
  fi
elif [ -n "$REMOTE_TRUNK" ]; then
  TRUNK="$REMOTE_TRUNK"
elif [ -n "$LOCAL_TRUNK" ]; then
  TRUNK="$LOCAL_TRUNK"
else
  echo "stale-branches: no trunk — no origin/HEAD, origin/main or main." >&2
  exit 2
fi
TRUNK_TREE="$(git rev-parse "$TRUNK^{tree}")"
TRUNK_LOCAL="${TRUNK#origin/}"

# `merge-tree --write-tree` arrived in git 2.38. An older git would make the `tree` test fail
# for every branch, which reads as "not proven" — the safe direction, and still a lie about
# which tests ran.
HAVE_TREE_TEST=true
git merge-tree --write-tree HEAD HEAD >/dev/null 2>&1 || HAVE_TREE_TEST=false

# The merged pull requests, as `<tip-sha><TAB><base>` lines, for the `pr` test. One bulk
# query, not one per branch: a repository with a hundred branches would otherwise make a
# hundred round trips.
#
# BLC_MERGED_PRS names a file to read instead of asking the forge. It exists because a test
# fixture has no forge, and `pr` is the only test that proves a squash merge — the merge this
# toolkit actually performs. A prover whose strongest test is never exercised is the defect
# this brief was filed about.
PR_RAW=""
PR_TEST="ran"
if [ -n "${BLC_MERGED_PRS:-}" ]; then
  PR_RAW="$(cat "$BLC_MERGED_PRS")"
elif forge="$(bash "$(dirname "$0")/detect-forge.sh" 2>/dev/null)"; then
  case "$forge" in
    github)
      if PR_RAW="$(gh pr list --state merged --limit 500 --json headRefOid,baseRefName \
                     --jq '.[] | "\(.headRefOid)\t\(.baseRefName)"' 2>/dev/null)"; then
        :
      else
        PR_TEST="the forge is github and \`gh\` could not answer"
      fi ;;
    *) PR_TEST="the forge is $forge, which this program cannot query yet" ;;
  esac
else
  PR_TEST="no forge was detected"
fi

# The base is filtered here rather than in the query, so the rule is in the program the suite
# can assert. A merged state alone proves a merge happened somewhere: a pull request merged
# into a release branch, or into another feature branch, is merged and its work is not here.
PR_HEADS="$(printf '%s\n' "$PR_RAW" | awk -F'\t' -v t="$TRUNK_LOCAL" '$2 == t { print $1 }')"

CURRENT="$(git symbolic-ref --quiet --short HEAD 2>/dev/null || true)"

# usage: proof_for <tip> — prints the name of the test that proved it, or nothing.
proof_for() {
  local tip="$1" merged_tree
  git merge-base --is-ancestor "$tip" "$TRUNK" 2>/dev/null && { printf 'ancestor'; return; }
  # Whole-line match. A substring match would let any tip that is a prefix of a recorded head
  # pass, and an abbreviated SHA in the override file would prove the wrong branch.
  printf '%s\n' "$PR_HEADS" | grep -qxF "$tip" && { printf 'pr'; return; }
  if $HAVE_TREE_TEST; then
    merged_tree="$(git merge-tree --write-tree "$TRUNK" "$tip" 2>/dev/null)" || return 0
    [ "$merged_tree" = "$TRUNK_TREE" ] && { printf 'tree'; return; }
  fi
  return 0
}

STALE=""
UNPROVEN=""
while read -r branch tip; do
  [ -n "$branch" ] || continue
  [ "$branch" = "$TRUNK_LOCAL" ] && continue
  proof="$(proof_for "$tip")"
  if [ -n "$proof" ]; then
    STALE="$STALE$branch	$proof	$tip
"
  else
    # Two fields, not three with an empty middle. IFS=$'\t' collapses runs of tabs because tab
    # is IFS whitespace, so an empty field shifts every field after it: the tip landed in the
    # wrong variable and `git log` ran on an empty range. A test asserting only the branch name
    # passed throughout, because the name is printed either way.
    UNPROVEN="$UNPROVEN$branch	$tip
"
  fi
done <<EOF
$(git for-each-ref --format='%(refname:short) %(objectname)' refs/heads/)
EOF

# ── Deletion ─────────────────────────────────────────────────────────────────
#
# Every named branch is proven again here, against the classification this run just built,
# rather than trusted from whatever the caller read. The report and the deletion are two
# commands with a person between them, and a branch can gain a commit in that gap — which is
# exactly the case a branch-name match got wrong on 2026-10-05.
#
# A test that could not run shrinks what is proven; it cannot make a proof wrong. So an absent
# forge deletes fewer branches and never the wrong one, and there is no reason to refuse.
if $DELETE; then
  # The saved tip goes under refs/blc/pruned/ before the branch goes away. A proven-stale
  # branch is in the trunk by definition, so this catches a bug in the prover rather than lost
  # work — which is a weaker thing to insure against, and worth one ref rather than a file.
  save_tip() {
    local name="$1" tip="$2" ref="refs/blc/pruned/$name" n=2
    while git rev-parse --verify --quiet "$ref" >/dev/null; do
      # A name can be pruned twice, with a different tip each time. Overwriting would discard
      # the only copy of the earlier one.
      ref="refs/blc/pruned/$name-$n"
      n=$((n + 1))
    done
    git update-ref "$ref" "$tip"
    printf '%s' "$ref"
  }

  status=0
  for name in "${TARGETS[@]}"; do
    if [ "$name" = "$TRUNK_LOCAL" ]; then
      echo "refused $name: it is the trunk." >&2
      status=1
      continue
    fi
    # Not redundant with git's own refusal. The tip is saved before the branch is removed, so
    # letting `git branch -D` do the refusing would leave a ref behind for a branch that is
    # still here. Checked by mutation: removing this fails the test.
    if [ "$name" = "$CURRENT" ]; then
      echo "refused $name: it is checked out." >&2
      status=1
      continue
    fi
    if ! tip="$(git rev-parse --verify --quiet "refs/heads/$name")"; then
      echo "refused $name: no such branch." >&2
      status=1
      continue
    fi
    proof="$(proof_for "$tip")"
    if [ -z "$proof" ]; then
      echo "refused $name: no test proves the trunk has this work." >&2
      status=1
      continue
    fi
    ref="$(save_tip "$name" "$tip")"
    git branch -D "$name" >/dev/null
    echo "deleted $name ($proof), tip kept at $ref"
  done
  exit $status
fi

if $TSV; then
  printf '%s' "$STALE" | while IFS=$'\t' read -r b p t; do
    [ -n "$b" ] && printf 'stale\t%s\t%s\t%s\n' "$b" "$p" "$t"
  done
  printf '%s' "$UNPROVEN" | while IFS=$'\t' read -r b t; do
    [ -n "$b" ] && printf 'unproven\t%s\t-\t%s\n' "$b" "$t"
  done
  exit 0
fi

stale_count="$(printf '%s' "$STALE" | grep -c . || true)"
unproven_count="$(printf '%s' "$UNPROVEN" | grep -c . || true)"

if [ -n "$TRUNK_NOTE" ]; then
  echo "stale-branches: trunk \`$TRUNK\` — $TRUNK_NOTE"
else
  echo "stale-branches: trunk \`$TRUNK\`"
fi
[ "$PR_TEST" = "ran" ] || echo "  The \`pr\` test did not run: $PR_TEST."
$HAVE_TREE_TEST || echo "  The \`tree\` test did not run: this git has no \`merge-tree --write-tree\` (needs 2.38)."
echo ""

if [ "$stale_count" -eq 0 ]; then
  echo "No branch is proven stale."
else
  echo "Proven stale ($stale_count). The trunk already has this work."
  printf '%s' "$STALE" | while IFS=$'\t' read -r b p t; do
    [ -n "$b" ] || continue
    [ "$b" = "$CURRENT" ] && b="$b (checked out)"
    printf '  %-48s %s\n' "$b" "$p"
  done
fi
echo ""

if [ "$unproven_count" -eq 0 ]; then
  echo "Every branch is proven."
else
  echo "Not proven ($unproven_count). No test says the trunk has this work."
  printf '%s' "$UNPROVEN" | while IFS=$'\t' read -r b t; do
    [ -n "$b" ] || continue
    printf '  %s\n' "$b"
    git log --oneline --no-decorate "$TRUNK..$t" | sed 's/^/    /'
  done
fi
