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
