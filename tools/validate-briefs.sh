#!/usr/bin/env bash
# Check a briefs directory against Contract v1, clauses BRIEFS-1 to BRIEFS-8.
#
# Usage: validate-briefs.sh [briefs-dir]     (default: docs/briefs)
#
# Exit 0 if no [defect] clause is violated, 1 otherwise. [judgment] findings are
# printed and never affect the exit status — the Contract says a judgment clause
# is surfaced for a human, so making it fail the build would silently promote it
# to a defect.
#
# The clause text lives in docs/contracts/v1.md. This script cites clause ids and
# does not restate them: a paraphrase here would be a fourth copy of the rules,
# which is the drift this Contract was extracted to end.
#
# No dependency beyond a POSIX shell and grep. CI is a thin trigger, so the check
# travels to environments that are not GitHub.

BRIEFS_DIR="${1:-docs/briefs}"

# Entries permitted to sit beside the numbered folders (BRIEFS-1).
KNOWN_NON_NUMBERED="_drafts README.md"

DEFECTS=0
JUDGMENTS=0

defect()   { printf '%s [defect] %s\n' "$1" "$2"; DEFECTS=$((DEFECTS + 1)); }
judgment() { printf '%s [judgment] %s\n' "$1" "$2"; JUDGMENTS=$((JUDGMENTS + 1)); }

if [ ! -d "$BRIEFS_DIR" ]; then
  printf 'error: not a directory: %s\n' "$BRIEFS_DIR" >&2
  exit 2
fi

# An entry is a brief candidate if it begins with four digits — the same test
# create-brief uses to find the maximum serial. Classifying on the prefix rather
# than on the full pattern keeps a malformed name in exactly one clause: it is a
# brief that is named wrong (BRIEFS-2), not an unexpected entry (BRIEFS-1).
is_brief_candidate() {
  case "$1" in
    [0-9][0-9][0-9][0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}

is_known_non_numbered() {
  local entry="$1" known
  for known in $KNOWN_NON_NUMBERED; do
    [ "$entry" = "$known" ] && return 0
  done
  return 1
}

# ── Collect ──────────────────────────────────────────────────────────────────

CANDIDATES=""
for path in "$BRIEFS_DIR"/*; do
  [ -e "$path" ] || continue
  entry="${path##*/}"

  if is_brief_candidate "$entry"; then
    # BRIEFS-1 — a brief is a folder. A file with a serial prefix is not one.
    if [ ! -d "$path" ]; then
      defect "BRIEFS-1" "$entry: has a serial prefix but is not a folder"
      continue
    fi
    CANDIDATES="$CANDIDATES$entry"$'\n'
  elif ! is_known_non_numbered "$entry"; then
    defect "BRIEFS-1" "$entry: neither a NNNN-slug/ folder nor a known non-numbered entry"
  fi
done

# ── BRIEFS-2 — slug and serial shape ─────────────────────────────────────────

WELL_FORMED=""
while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  if printf '%s' "$entry" | grep -qE '^[0-9]{4}-[a-z0-9-]+$'; then
    WELL_FORMED="$WELL_FORMED$entry"$'\n'
  else
    defect "BRIEFS-2" "$entry: does not match NNNN-slug with a lowercase slug"
  fi
done <<EOF
$CANDIDATES
EOF

# Only well-formed names have a serial that can be trusted, so every clause below
# reads from WELL_FORMED. A malformed name is reported once by BRIEFS-2 rather
# than cascading into the clauses that would parse it wrong.

# ── BRIEFS-3 — serials are unique ────────────────────────────────────────────

SERIALS=$(printf '%s' "$WELL_FORMED" | sed 's/^\([0-9][0-9][0-9][0-9]\)-.*/\1/' | sort)
DUPES=$(printf '%s\n' "$SERIALS" | grep -v '^$' | uniq -d)
if [ -n "$DUPES" ]; then
  while IFS= read -r serial; do
    [ -n "$serial" ] || continue
    defect "BRIEFS-3" "$serial: used by more than one folder"
  done <<EOF
$DUPES
EOF
fi

# ── BRIEFS-4, BRIEFS-5 — the brief exists and its identity line is well formed ─

DECLARED_SERIALS=""
DEPENDENCIES=""

while IFS= read -r entry; do
  [ -n "$entry" ] || continue
  serial="${entry%%-*}"
  brief="$BRIEFS_DIR/$entry/brief.md"

  if [ ! -f "$brief" ]; then
    defect "BRIEFS-4" "$entry: contains no brief.md"
    continue
  fi

  DECLARED_SERIALS="$DECLARED_SERIALS$serial"$'\n'

  identity=$(grep -m1 '^\*\*Serial:\*\*' "$brief")
  if [ -z "$identity" ]; then
    defect "BRIEFS-5" "$entry: no identity line"
    continue
  fi

  found_serial=$(printf '%s' "$identity" | sed 's/^\*\*Serial:\*\* *#\([0-9]*\).*/\1/')
  [ "$found_serial" = "$serial" ] \
    || defect "BRIEFS-5" "$entry: identity line says #$found_serial, folder says $serial"

  printf '%s' "$identity" | grep -qE '\*\*Created:\*\* *[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' \
    || defect "BRIEFS-5" "$entry: Created is missing or not ISO-8601 UTC"

  printf '%s' "$identity" | grep -qE '\*\*Author:\*\* *[^ @]+@[^ @]+\.[^ @]+' \
    || defect "BRIEFS-5" "$entry: Author is missing or not email-shaped"

  if printf '%s' "$identity" | grep -q '\*\*Depends on:\*\*'; then
    deps=$(printf '%s' "$identity" | sed 's/.*\*\*Depends on:\*\*//')
    for dep in $(printf '%s' "$deps" | grep -oE '#[0-9]{4}' | tr -d '#'); do
      DEPENDENCIES="$DEPENDENCIES$entry $dep"$'\n'
    done
  else
    defect "BRIEFS-5" "$entry: identity line has no Depends on"
  fi
done <<EOF
$WELL_FORMED
EOF

# ── BRIEFS-6 — no dangling dependencies ──────────────────────────────────────

while IFS=' ' read -r entry dep; do
  [ -n "$dep" ] || continue
  printf '%s' "$DECLARED_SERIALS" | grep -qx "$dep" \
    || defect "BRIEFS-6" "$entry: depends on #$dep, which does not exist"
done <<EOF
$DEPENDENCIES
EOF

# ── BRIEFS-7 — drafts are unnumbered ─────────────────────────────────────────

if [ -d "$BRIEFS_DIR/_drafts" ]; then
  for path in "$BRIEFS_DIR"/_drafts/*; do
    [ -e "$path" ] || continue
    entry="${path##*/}"
    is_brief_candidate "$entry" \
      && defect "BRIEFS-7" "_drafts/$entry: a draft carries a four-digit prefix"
  done
fi

# ── BRIEFS-8 — serials are contiguous ────────────────────────────────────────
#
# [judgment], not [defect]: a removed brief legitimately retires its number, so a
# gap is a question for a human rather than a build failure.

UNIQUE_SERIALS=$(printf '%s' "$DECLARED_SERIALS" | grep -v '^$' | sort -u)
if [ -n "$UNIQUE_SERIALS" ]; then
  expected=1
  while IFS= read -r serial; do
    [ -n "$serial" ] || continue
    # Strip leading zeros before comparing; 0010 is not octal here.
    actual=$(printf '%s' "$serial" | sed 's/^0*//')
    [ -n "$actual" ] || actual=0
    if [ "$actual" -ne "$expected" ]; then
      if [ "$expected" -eq 1 ]; then
        judgment "BRIEFS-8" "serials start at $serial, not 0001"
      else
        judgment "BRIEFS-8" "serials jump from $(printf '%04d' $((expected - 1))) to $serial"
      fi
      expected="$actual"
    fi
    expected=$((expected + 1))
  done <<EOF
$UNIQUE_SERIALS
EOF
fi

# ── Report ───────────────────────────────────────────────────────────────────
#
# The count is of clauses this script decides, not of clauses in the Contract.
# Saying "8 clauses checked" when the Contract grows a ninth would overstate
# coverage, which is the failure this artifact exists to prevent.
#
# The brief count is reported for the same reason. Without it, a caller cannot
# tell compliance from an empty directory: both are zero defects and exit 0, and
# a test asserting only the exit code would pass on a tree containing nothing.

BRIEF_COUNT=$(printf '%s' "$WELL_FORMED" | grep -c '[^[:space:]]')

printf '\nvalidate-briefs: %s — %d brief(s), 8 clauses decided, %d defect(s), %d judgment(s)\n' \
  "$BRIEFS_DIR" "$BRIEF_COUNT" "$DEFECTS" "$JUDGMENTS"

[ "$DEFECTS" -eq 0 ] || exit 1
exit 0
