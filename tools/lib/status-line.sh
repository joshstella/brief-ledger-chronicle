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
# Fenced blocks are skipped, and that is not a refinement — it is the third way these two
# readers could disagree. Anchoring defeats an example with prose in front of it, but not an
# example sitting at column 0 inside a fence, which is exactly how `docs/briefs/README.md`
# shows the line. A ledger that documents its own format would have handed a reader the
# example instead of its own status. Found in review, before any ledger here did it.
#
# Every backtick on the line is removed, not only the enclosing pair. No status line carries
# a backtick anywhere else, and both predecessors did the same, so this is stated rather
# than narrowed — a caller that trusted "the surrounding backticks" would be trusting
# something the code does not do.
#
# Leading and trailing whitespace go too, so callers can match on `blc/*` without each one
# re-deciding what to trim.
#
# ── One scan, two answers ────────────────────────────────────────────────────
#
# `blc_ledger_scan` is the only thing here that reads a file. Both public questions are
# wrappers over it, because the second caller arrived in phase `c` wanting the *other* half
# of what this awk already computes.
#
# `BRIEFS-10` asks whether a ledger's frontmatter and fences are closed. The locator has
# always known: it tracks fence state to skip them, and it falls back precisely when the file
# ends inside one. Writing that tracking a second time in `validate-briefs.sh` would put two
# fence implementations in this toolkit — which is #0013's second defect, two readers
# disagreeing about a file's structure, rebuilt inside the brief written to prevent it.
#
# This is also why the recovery behaviour needs a clause at all. The locator deliberately
# succeeds on a malformed ledger: it reads through unterminated frontmatter and falls back
# past an unclosed fence. That is right for a reporter and it makes the malformation
# invisible, so the complaint cannot be derived from the locator's *result* — only from the
# state it passed through on the way.
#
# The file is still named for the locator. Renaming it would move a path the ownership map,
# `install.sh`, and three test files all key on, and phase `c` is large enough already —
# recorded as a complication rather than done quietly.
blc_ledger_scan() {
  awk '
    function is_status(l) { return l ~ /^[[:space:]]*`?blc\/[0-9]+[[:space:]]/ }

    { line = $0; sub(/\r$/, "", line) }

    # Frontmatter is only frontmatter on line 1, and `fm` records the three states the
    # clause distinguishes: absent, opened-and-closed, opened-and-never-closed.
    NR == 1 && line == "---" { fm = 1; next }
    fm == 1 && line == "---" { fm = 2; next }

    # Remember the first candidate anywhere, fences included. Only ever used for the
    # unterminated-fence fallback in END.
    anywhere == "" && is_status(line) { anywhere = line }

    # A fence opens on three or more backticks or tildes. It closes only on the same
    # character, at least as long. Toggling on any delimiter — the first version of this —
    # let a ```` block containing ``` , or a ``` block containing ~~~ , read as closed, and
    # the locator then returned the example it was meant to skip. A delimiter that does not
    # match the open one is content, not a fence.
    # Three-or-more written as ```` ```` `* ```` rather than ``{3,}``: mawk 1.3.4 does not
    # support interval expressions, and read `{3,}` literally. Under it the locator returned
    # the fenced example — a portability defect that is invisible on any machine with gawk,
    # which is every machine this has been run on.
    match(line, /^[[:space:]]*(````*|~~~~*)[[:space:]]*/) {
      d = substr(line, RSTART, RLENGTH); gsub(/[[:space:]]/, "", d)
      if (!fence)                                      { fence = 1; fch = substr(d,1,1); flen = length(d) }
      else if (substr(d,1,1) == fch && length(d) >= flen) { fence = 0 }
      next
    }

    fence { next }
    # No `exit` here. The first version stopped at the first status line, which was correct
    # for the only question it answered and wrong the moment a second caller wanted to know
    # how the file ends — exiting early reports a fence closed because the scan stopped
    # before reaching the line that never closes it.
    outside == "" && is_status(line) { outside = line }

    END {
      # The file ended inside a fence that never closed. Treating the remainder as code
      # would hide a live brief’s status from every reader — the same unbounded skip this
      # phase reversed for unterminated frontmatter, and refused there for the same reason.
      # A malformed fence is a defect in the ledger, not a reason to report that it has no
      # status at all.
      if (outside != "")           printf "status\t%s\n", outside
      else if (fence && anywhere != "") printf "status\t%s\n", anywhere

      printf "frontmatter\t%s\n", (fm == 1 ? "open" : (fm == 2 ? "closed" : "none"))
      printf "fence\t%s\n", (fence ? "open" : "closed")
    }
  ' "$1" 2>/dev/null
}

blc_status_line() {
  blc_ledger_scan "$1" \
    | sed -n 's/^status'"$(printf '\t')"'//p' \
    | tr -d '`' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# Emit `open`, `closed`, or `none` for one structural fact: `frontmatter` or `fence`.
# `BRIEFS-10` complains when either is `open`.
blc_ledger_structure() {
  blc_ledger_scan "$1" \
    | sed -n 's/^'"$2$(printf '\t')"'//p'
}
