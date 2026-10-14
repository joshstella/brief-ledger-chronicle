#!/usr/bin/env bash
# t/run.sh — the rules this fixture cannot exercise.
#
# Six of the nine rules in next.sh never fire against this repository, because this repository
# closes its phases on the day it opens them. Testing them needs a record that is wrong in
# ways this one is not, so each case here is a hand-written snapshot in read.sh's own shape,
# fed through BLIC_SNAPSHOT. The repository remains the fixture for everything it can show.
#
#   bash t/run.sh        run them
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEXT="$HERE/../next.sh"
export BLIC_ME="me@example.test"
pass=0; fail=0

brief() { # brief <serial> <state> <closed> <has_ledger> <phases-json>
  printf '{"serial":"%s","slug":"%s-x","dir":"d","title":"a brief","state":"%s","status_line":"l","owner":"","author":"me@example.test","assignee":"me@example.test","mine":true,"created":"","closed":"%s","touched":"","has_ledger":%s,"phases":[%s]}' \
    "$1" "$1" "$2" "$3" "$4" "$5"
}
phase() { printf '{"id":"%s","label":"","state":"%s","pointer":"%s"}' "$1" "$2" "${3:-}"; }

check() { # check <name> <expected-rule> <briefs-json> [main-subjects] [declarations]
  local name="$1" want="$2" json="$3" subjects="${4:-}" decls="${5:-[]}" out
  local f; f="$(mktemp)"
  printf '[%s]' "$json" > "$f"
  out="$(BLIC_SNAPSHOT="$f" BLIC_MAIN_SUBJECTS="$subjects" BLIC_DECLARATIONS="$decls" \
        bash "$NEXT" --why --all 2>&1 || true)"
  rm -f "$f"
  if printf '%s' "$out" | grep -q "rule $want"; then
    pass=$((pass + 1)); printf 'ok   %-18s %s\n' "$name" "$(printf '%s' "$out" | sed -n '2p')"
  else
    fail=$((fail + 1)); printf 'FAIL %-18s wanted rule %s, got:\n%s\n' "$name" "$want" "$out"
  fi
}

# The case the brief names by hand: the phase landed on the trunk and the line still says open.
check phase-merged PHASE-MERGED \
  "$(brief 0101 in-progress "" true "$(phase a in-progress brief/0101-a)")" \
  '[#0101a] the phase that landed (#9)'

# Every phase closed, the brief still open. BRIEFS-11's neighbour, and the one orient misses.
check all-phases-done ALL-PHASES-DONE \
  "$(brief 0102 in-progress "" true "$(phase a done PR#1),$(phase b done PR#2)")"

# A sequence with nothing in flight. The ledger says what is next; nothing says to start it.
check no-phase-open NO-PHASE-OPEN \
  "$(brief 0103 in-progress "" true "$(phase a done PR#1),$(phase b pending)")"

# The pointer names a branch that no longer exists. The line is unreadable, not merely stale.
check branch-gone BRANCH-GONE \
  "$(brief 0104 in-progress "" true "$(phase a in-progress brief/0104-a-deleted)")"

# A filed serial with no ledger: the window the project rules call invisible.
check no-ledger NO-LEDGER \
  "$(brief 0105 planned "" false "")"

# A ledger whose status line could not be found. read.sh reports this as `no-line`.
check no-status-line NO-STATUS-LINE \
  "$(printf '{"serial":"0106","slug":"0106-x","dir":"d","title":"t","state":"no-line","status_line":"","owner":"","author":"me@example.test","assignee":"me@example.test","mine":true,"created":"","closed":"","touched":"","has_ledger":true,"phases":[]}')"

# A declaration of mine that is still standing.
check declaration DECLARATION \
  "$(brief 0107 done 2026-01-01 true "$(phase a done PR#1)")" '' \
  '[{"who":"me@example.test","mine":true,"touched":"2026-10-01T00:00:00Z","claims":["#0041 picked up"]}]'

# Somebody else's brief is not mine to do.
out="$(f="$(mktemp)"; printf '[{"serial":"0108","slug":"s","dir":"d","title":"t","state":"in-progress","status_line":"l","owner":"other@example.test","author":"other@example.test","assignee":"other@example.test","mine":false,"created":"","closed":"","touched":"","has_ledger":true,"phases":[]}]' > "$f"
  BLIC_SNAPSHOT="$f" BLIC_DECLARATIONS='[]' bash "$NEXT" 2>&1; rm -f "$f")"
if printf '%s' "$out" | grep -q 'nothing is yours to do'; then
  pass=$((pass + 1)); printf 'ok   %-18s %s\n' not-mine 'a brief owned by somebody else is silent'
else
  fail=$((fail + 1)); printf 'FAIL %-18s got:\n%s\n' not-mine "$out"
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
