# The ledger status-line locator, defined once.
#
# Sourced, never invoked: no shebang, no execute bit. See tools/lib/phase-row.sh for why
# `tools/lib/` is the declaration and install.sh and tests/test_source_tree.sh both key on
# the path.
#
# Three readers want this line. `open-briefs.sh` reports drift from it, `list-briefs.sh`
# renders the timeline from it — and `orient.sh` through that — and `validate-briefs.sh`
# joins them in #0014 phase `c`, where it gates. Before this file there were two
# implementations that disagreed by design, which is the shape of #0013's second defect:
# two readers with different ideas of where the line lives.
#
# The search covers the whole file and the match is anchored. Both halves are load-bearing,
# and each one was a bug in one of the two locators it replaces:
#
#   whole file   `open-briefs.sh` read positionally — title, then the next line — which is
#                cheap and wrong for a ledger with a blank line after its title, or one
#                whose line sits further down. It reported those as having no line at all.
#
#   anchored     `list-briefs.sh` searched the whole file unanchored, so a ledger whose
#                prose quotes an example status line above its own returned *the prose
#                sentence*. A gate reading that would parse garbage phase ids and fail a
#                correct ledger. Finding the wrong line is worse than finding none.
#
# Checked against every ledger in this repository: identical to the positional read on all
# of them. The two shapes above do not occur here yet, which is exactly why the disagreement
# survived unnoticed — see tests/test_status_line.sh, where they are fixtures.
#
# Leading whitespace and the surrounding backticks are stripped, so callers can match on
# `blc/*` without each one re-deciding what to trim.
blc_status_line() {
  grep -m1 -E '^[[:space:]]*`?blc/[0-9]+[[:space:]]' "$1" 2>/dev/null \
    | tr -d '`' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}
