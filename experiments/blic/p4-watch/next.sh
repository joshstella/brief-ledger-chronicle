#!/usr/bin/env bash
# blic next — what is mine to do next, derived from the record.
#
# Not a state dump. Each line is an action with a verb, and each is produced by one rule over
# the frozen read surface plus git. `--why` prints the rule that fired, because a derived
# action nobody can audit is a guess with better typography.
#
# Read-only. The only git commands are reads of refs and subjects.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/json.sh
. "$HERE/lib/json.sh"

READ_SH="${BLIC_READ_SH:-$HERE/../read.sh}"
LIMIT="${BLIC_LIMIT:-8}"
SHOW_ALL=0
WHY=0
for a in "$@"; do
  case "$a" in
    --all) SHOW_ALL=1 ;;
    --why) WHY=1 ;;
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "blic next: unknown option: $a" >&2; exit 2 ;;
  esac
done

# ── Inputs ───────────────────────────────────────────────────────────────────
# BLIC_SNAPSHOT lets a fixture stand in for the repository. The rules that no real brief
# exercises are tested that way; see t/run.sh.
if [ -n "${BLIC_SNAPSHOT:-}" ]; then
  BRIEFS_JSON="$(cat "$BLIC_SNAPSHOT")"
  DECLS_JSON="${BLIC_DECLARATIONS:-[]}"
  ME="${BLIC_ME:-$(git config user.email 2>/dev/null || true)}"
else
  BRIEFS_JSON="$(bash "$READ_SH" briefs)"
  DECLS_JSON="$(bash "$READ_SH" declarations)"
  ME="$(git config user.email 2>/dev/null || true)"
fi

# The trunk's commit subjects, read once. This is how a merge is detected without a forge:
# blc-commit-push-pr writes `[#NNNNx] ...` and blc-close-brief writes `docs: close #NNNN`,
# so the subject survives a squash even though the branch's commits do not. It is a
# convention, not proof — tools/stale-branches.sh says only the forge can prove a squash —
# and the limit is reported rather than hidden.
TRUNK=main
git rev-parse --verify --quiet origin/main >/dev/null 2>&1 && TRUNK=origin/main
MAIN_SUBJECTS=""
[ -n "${BLIC_SNAPSHOT:-}" ] || MAIN_SUBJECTS="$(git log "$TRUNK" --format=%s 2>/dev/null || true)"
MAIN_SUBJECTS="${BLIC_MAIN_SUBJECTS:-$MAIN_SUBJECTS}"

in_trunk() { printf '%s\n' "$MAIN_SUBJECTS" | grep -qF "$1"; }
branch_exists() { git rev-parse --verify --quiet "refs/heads/$1" >/dev/null 2>&1; }

# ── Rules ────────────────────────────────────────────────────────────────────
# Each emits `rank<TAB>rule<TAB>key<TAB>text`. Rank orders the list: 1 blocks the trunk,
# 2 is a record line that lies, 3 is a record line that is merely incomplete, 4 is hygiene.
ITEMS=""
emit() { ITEMS+="$1	$2	$3	$4"$'\n'; }

first_tok() { printf '%s' "${1%%(*}"; }

while IFS= read -r rec; do
  [ -n "$rec" ] || continue
  serial="$(blic_field "$rec" serial)"
  [ -n "$serial" ] || continue
  mine="$(blic_field "$rec" mine)"
  [ "$mine" = true ] || continue
  state="$(first_tok "$(blic_field "$rec" state)")"
  closed="$(blic_field "$rec" closed)"
  has_ledger="$(blic_field "$rec" has_ledger)"
  title="$(blic_field "$rec" title)"
  short="${title:0:46}"

  # Phase scan: what the status line claims, and what the trunk shows.
  n_open=0; n_pending=0; n_done=0; n_total=0
  open_desc=""; pending_first=""; merged_open=""
  while IFS= read -r ph; do
    [ -n "$ph" ] || continue
    pid="$(blic_field "$ph" id)"
    pstate="$(first_tok "$(blic_field "$ph" state)")"
    pointer="$(blic_field "$ph" pointer)"
    n_total=$((n_total + 1))
    case "$pstate" in
      in-progress|deferred)
        n_open=$((n_open + 1))
        if in_trunk "[#${serial}${pid}]"; then
          merged_open="$pid"
        else
          open_desc="$pid${pointer:+ on ${pointer%%,*}}"
        fi ;;
      pending) n_pending=$((n_pending + 1)); [ -n "$pending_first" ] || pending_first="$pid" ;;
      done|skipped) n_done=$((n_done + 1)) ;;
    esac
  done < <(blic_phases "$rec")

  case "$state" in
    in-progress|deferred)
      if [ -n "$merged_open" ]; then
        # The case the brief names: the phase landed and the line still says it is open.
        emit 1 PHASE-MERGED "$serial" "#$serial phase $merged_open is in the trunk and the line still says open — close phase $merged_open (blc-next-brief-phase)"
      elif [ "$n_total" -gt 0 ] && [ "$n_open" = 0 ] && [ "$n_pending" = 0 ]; then
        emit 1 ALL-PHASES-DONE "$serial" "#$serial every phase is done and the brief is not — close the brief (blc-close-brief)"
      elif [ "$n_open" = 0 ] && [ -n "$pending_first" ]; then
        emit 1 NO-PHASE-OPEN "$serial" "#$serial nothing is in flight and phase $pending_first is pending — start phase $pending_first (blc-next-brief-phase)"
      elif [ -n "$open_desc" ]; then
        br="${open_desc#* on }"
        if [ "$br" != "$open_desc" ] && ! branch_exists "$br"; then
          emit 2 BRANCH-GONE "$serial" "#$serial phase ${open_desc%% *} names branch $br and the branch is gone — fix the pointer or re-cut it"
        else
          # The ledger says a phase is open and nothing more. The one honest refinement git
          # can add is whether the branch carries work the trunk has not seen.
          ahead="$(git rev-list --count "$TRUNK..$br" 2>/dev/null || echo 0)"
          if [ "$ahead" -gt 0 ]; then
            s=s; [ "$ahead" = 1 ] && s=""
            emit 1 IN-FLIGHT "$serial" "#$serial phase ${open_desc%% *} has $ahead commit$s not in $TRUNK — review and merge it (blc-review-pr, blc-commit-push-pr)"
          else
            emit 1 IN-FLIGHT "$serial" "#$serial phase ${open_desc%% *} is open on $br with nothing committed — do the work"
          fi
        fi
      else
        emit 1 IN-FLIGHT "$serial" "#$serial in-progress with no phase row — $short"
      fi ;;
    done)
      if [ -z "$closed" ]; then
        # BRIEFS-11. One line per brief would be 16 lines, so these group.
        emit 3 NO-CLOSE-DATE "$serial" "$serial"
      fi ;;
    planned|no-line)
      if [ "$has_ledger" = false ]; then
        emit 2 NO-LEDGER "$serial" "#$serial is filed and has no ledger — start the brief (blc-start-brief)"
      else
        emit 2 NO-STATUS-LINE "$serial" "#$serial has a ledger with no status line — nothing can read its state"
      fi ;;
  esac
done < <(blic_records "$BRIEFS_JSON" serial)

# A declaration is a claim on unfiled work. It is mine to clear once the serial is filed, and
# the record carries no expiry, so staleness is reported by age rather than decided.
while IFS= read -r d; do
  [ -n "$d" ] || continue
  who="$(blic_field "$d" who)"
  [ "$who" = "$ME" ] || continue
  touched="$(blic_field "$d" touched)"
  emit 2 DECLARATION "$who" "my declaration in docs/blc/state/$who.md still claims work (last touched ${touched:0:10}) — clear it if it landed"
done < <(blic_records "$DECLS_JSON" who)

# Branch hygiene. A branch whose phase commit is in the trunk is merged in every way this
# prototype can see; the forge could still disagree, so the line says prune rather than delete.
if [ -z "${BLIC_SNAPSHOT:-}" ]; then
  stale=""
  while IFS= read -r b; do
    [ -n "$b" ] || continue
    subj="$(git log -1 --format=%s "$b" 2>/dev/null || true)"
    key=""
    case "$subj" in
      \[#*\]*) key="${subj%%]*}]" ;;
      docs:\ close\ \#*) key="$(printf '%s' "$subj" | sed -n 's/^\(docs: close #[0-9]*\).*/\1/p')" ;;
    esac
    [ -n "$key" ] || continue
    in_trunk "$key" && stale+="$b "
  done < <(git branch --format='%(refname:short)' | grep -v "^${TRUNK#origin/}$")
  if [ -n "$stale" ]; then
    n=$(printf '%s\n' $stale | wc -l)
    emit 4 MERGED-BRANCH "branches" "$n local branches are merged into $TRUNK — blc-prune-stale-branches"
  fi
fi

# ── Output ───────────────────────────────────────────────────────────────────
# Sixteen briefs with the same defect are one line, not sixteen. The serials go on a
# continuation line so the action and its subjects are both readable.
no_close=""
kept=""
while IFS=$'\t' read -r rank rule key text; do
  [ -n "$rank" ] || continue
  if [ "$rule" = NO-CLOSE-DATE ]; then no_close+="$key "; continue; fi
  kept+="$rank	$rule	$text"$'\n'
done < <(printf '%s' "$ITEMS" | sort -t'	' -k1,1n -k3,3)
if [ -n "$no_close" ]; then
  n=$(printf '%s' "$no_close" | wc -w)
  kept+="3	NO-CLOSE-DATE	$n briefs say done and carry no Closed date — write the close date (BRIEFS-11)"$'\n'
fi

n_briefs="$(blic_records "$BRIEFS_JSON" serial | grep -c '"serial"' || true)"
printf 'blic next · %s · %s briefs · %s\n' "${ME:-no git identity}" "$n_briefs" "$(date +%H:%M)"

total=0; shown=0
while IFS=$'\t' read -r rank rule text; do
  [ -n "$rank" ] || continue
  total=$((total + 1))
  if [ "$SHOW_ALL" = 0 ] && [ "$shown" -ge "$LIMIT" ]; then continue; fi
  shown=$((shown + 1))
  printf '%2d. %s\n' "$total" "$text"
  [ "$rule" = NO-CLOSE-DATE ] && printf '     %s\n' "${no_close% }"
  [ "$WHY" = 1 ] && printf '      rule %s\n' "$rule"
done < <(printf '%s' "$kept" | sort -t'	' -k1,1n -s)

if [ "$total" = 0 ]; then
  printf 'nothing is yours to do. The record is consistent and nothing is in flight.\n'
elif [ "$shown" -lt "$total" ]; then
  printf '     … %s more, blic next --all\n' "$((total - shown))"
fi
