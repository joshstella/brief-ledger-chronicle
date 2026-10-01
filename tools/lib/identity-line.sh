# The brief identity-line reader, defined once.
#
# Sourced, never invoked: no shebang, no execute bit. See tools/lib/phase-row.sh for why
# `tools/lib/` is the declaration and install.sh and tests/test_source_tree.sh both key on
# the path.
#
# `validate-briefs.sh` (BRIEFS-5, BRIEFS-6) and `list-briefs.sh` (its dependency column) read
# the identity line only through this file, so they cannot disagree about which line it is or
# where a field ends. tests/test_identity_line.sh fingerprints the common spellings of a local
# parser in tools/; it is a fingerprint, not a proof.
#
# A field ends at the next `·`, so a `#NNNN` in a field after `Depends on` is not a
# dependency. Several dependencies are separated by commas, never by `·`.
#
# Tolerant on purpose, like phase-row.sh: it finds a field by its label and ignores fields it
# does not know, so a new field on the line costs no reader change. Shape is the caller's
# business — BRIEFS-5 decides what a good `Created` looks like.
#
# Function names are prefixed `blc_`; see tools/lib/phase-row.sh.

# Print the identity line of the brief at `$1`, or nothing and return 1 if it has none: the
# first line that begins `**Serial:**`. It need not sit directly under the H1; the Contract
# does not require that.
blc_identity_line() {
  grep -m1 '^\*\*Serial:\*\*' "$1" 2>/dev/null
}

# Print the value of field `$2` on identity line `$1`, or nothing and return 1 if the line has
# no such field. A field present with an empty value prints nothing and returns 0, so a caller
# can tell "missing" from "blank".
#
# The value runs from the label to the next `·` or the end of the line. The first occurrence
# of the label wins. Only spaces are trimmed: BRIEFS-5 rejects a tab after `Serial` and after
# `Created`, and a shared reader must not loosen a `[defect]` gate.
blc_identity_field() {
  local line="$1" label="$2" value
  case "$line" in
    *"**$label:**"*) ;;
    *) return 1 ;;
  esac
  value="${line#*"**$label:**"}"
  value="${value%%·*}"
  value="${value#"${value%%[! ]*}"}"
  value="${value%"${value##*[! ]}"}"
  printf '%s' "$value"
}

# The email a brief is assigned to, read from identity line `$1`: `Owner`, or `Author` when
# there is no `Owner`. Prints the email and returns 0. Returns 1, printing nothing, when the
# line has neither. Returns 2 when the field it chose is not one email, and prints that field
# as `<label> '<value>'` so the caller can say what is wrong in its own words.
#
# The one place this file decides shape. `list-briefs.sh --owner` and `jira-csv.sh` must agree
# about whose a brief is, and an email check written twice is two answers. A malformed `Owner`
# does not fall back to `Author`: `Owner` exists to say the filer is not the executor. `Author`
# is checked here too, because BRIEFS-5's check is not anchored and passes `a@x.org, b@x.org`.
# Backticks, quotes and angle brackets are markup around an address, and a comma means more
# than one; each would match no one.
BLC_EMAIL_CHAR="[^ @\`\"'<>,]"
BLC_EMAIL_RE="^${BLC_EMAIL_CHAR}+@${BLC_EMAIL_CHAR}+\\.${BLC_EMAIL_CHAR}+\$"
blc_identity_assignee() {
  local label=Owner email
  if ! email=$(blc_identity_field "$1" Owner); then
    label=Author
    email=$(blc_identity_field "$1" Author) || return 1
  fi
  if printf '%s' "$email" | grep -qE "$BLC_EMAIL_RE"; then
    printf '%s' "$email"
    return 0
  fi
  printf "%s '%s'" "$label" "$email"
  return 2
}
