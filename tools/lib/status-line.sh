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
# example sitting at column 0 inside a fence, which is exactly how `docs/blc/briefs/README.md`
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
    # BRIEFS-11 reads this. It is matched by the same scan as the status line, and for the
    # same reason: a ledger that shows the field in a fenced example is documenting the
    # format, not recording its own close, and a reader grepping the raw file cannot tell
    # the two apart. That is not hypothetical here — the status line had this exact fault
    # and it was found in review before any ledger hit it.
    function is_closed(l) { return l ~ /^[[:space:]]*\*\*Closed:\*\*/ }

    { line = $0; sub(/\r$/, "", line) }

    # Remember the first candidate anywhere — inside fences, inside frontmatter, anywhere.
    # Used only by the fallbacks in END, and it has to run before every skip below: when it
    # sat after the frontmatter rule it never ran inside an unterminated block, so the
    # fallback for that block had nothing to fall back to.
    anywhere == "" && is_status(line) { anywhere = line }

    # Frontmatter is only frontmatter on line 1, and `fm` records the three states the
    # clause distinguishes: absent, opened-and-closed, opened-and-never-closed.
    #
    # It runs from the opening `---` to the next one, and everything between is YAML — so a
    # fence delimiter in there is a string, not a fence. Skipping the interior is what makes
    # that true. Review found the older version opening a fence on a ``` inside a YAML block
    # scalar, which drew a false BRIEFS-10 complaint about a legal ledger and made the
    # locator fall back past the rest of the file.
    #
    # The converse — a `---` inside a fence closing the frontmatter — is *not* guarded, on
    # purpose. See tests/test_clauses.sh: frontmatter ends at the first `---` after line 1,
    # which is what every markdown tool does, and a fence cannot have opened before it
    # because the interior is skipped. Guarding it would invent a second rule for a document
    # shape no parser agrees with us about.
    NR == 1 && line == "---" { fm = 1; next }
    fm == 1 && line == "---" { fm = 2; next }
    fm == 1                  { next }

    # A fence opens on three or more backticks or tildes. It closes only on the same
    # character, at least as long. Toggling on any delimiter — the first version of this —
    # let a ```` block containing ``` , or a ``` block containing ~~~ , read as closed, and
    # the locator then returned the example it was meant to skip. A delimiter that does not
    # match the open one is content, not a fence.
    # Three-or-more written as ```` ```` `* ```` rather than ``{3,}``. mawk 1.3.4 does support
    # interval expressions; what it does differently is match them minimally where gawk matches
    # maximally, so `` ```{3,} `` against a four-backtick fence sets RLENGTH to 3 and the closing
    # rule compares the wrong length. The `` `* `` spelling is greedy under both and measures 4.
    # Nothing here is currently wrong under mawk — the suite runs green under it — and this
    # comment is the reason not to "simplify" the spelling back.
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
    # Sits below every skip above, so a fenced or frontmatter example never sets it.
    closed == "" && is_closed(line) { closed = "yes" }

    END {
      # The file ended inside a fence that never closed. Treating the remainder as code
      # would hide a live brief’s status from every reader — the same unbounded skip this
      # phase reversed for unterminated frontmatter, and refused there for the same reason.
      # A malformed fence is a defect in the ledger, not a reason to report that it has no
      # status at all.
      # The fallback covers both unbounded skips, not just the fence. An unterminated
      # frontmatter block skips to end of file exactly as an unterminated fence does, and
      # phase `b` reversed the old behaviour there for this reason: one stray `---` used to
      # hide the whole status of a ledger from one tool and not the other.
      # (No ASCII apostrophe anywhere in this program: it is single-quoted shell, and a
      # stray one silently ends the string. That is why the line above spells it `brief’s`.)
      if (outside != "")                         printf "status\t%s\n", outside
      else if ((fence || fm == 1) && anywhere != "") printf "status\t%s\n", anywhere

      printf "frontmatter\t%s\n", (fm == 1 ? "open" : (fm == 2 ? "closed" : "none"))
      printf "fence\t%s\n", (fence ? "open" : "closed")
      printf "closed\t%s\n", (closed == "" ? "no" : "yes")
    }
  ' "$1" 2>/dev/null
}

blc_status_line() {
  blc_ledger_scan "$1" | blc_scan_field status | tr -d '`' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# The brief-level state token from a status line: the `done(PR#45)` in
# `blc/2 #0045 done(PR#45) a:done(PR#44)`. The pointer is kept, because the one caller that
# renders it wants it and the one that compares it can cut it.
#
# This lived inside `list-briefs.sh` until `BRIEFS-11` needed the same answer. It moved here
# rather than being written twice, for the reason stated at the top of `validate-briefs.sh`:
# a validator with its own private copy would be a reader free to disagree with the tool
# that renders the timeline, and the two would drift without either being wrong on its own.
#
# The schema and serial are stripped off the front and the phase entries off the back,
# instead of taking a field by position. `done(commit 92a7168)` is a real state in this
# repository and holds a space, so a positional read returns `done(commit` and the oldest
# closed briefs match nothing.
blc_status_state() {
  printf '%s' "$1" \
    | sed -E 's/^blc\/[0-9]+[[:space:]]+#[0-9]+[[:space:]]+//; s/[[:space:]]+[0-9a-z]+:.*$//'
}

# Pull one field out of a scan already performed. Reads stdin, so a caller wanting more
# than one answer pays for one scan — see `blc_ledger_facts`.
#
# The field name is matched as a literal against a known set rather than interpolated into
# a `sed` expression, which is what this did first. That form was not injectable, but an
# unknown field returned empty output and exit 0, and both `BRIEFS-10` call sites read
# empty as "nothing to complain about". A typo in a field name would have disabled half a
# clause in silence — the failure this brief is about, in the code enforcing it.
blc_scan_field() {
  case "$1" in
    status|frontmatter|fence|closed) ;;
    *) printf 'blc_scan_field: unknown field: %s\n' "$1" >&2; return 2 ;;
  esac
  awk -F'\t' -v want="$1" '$1 == want { sub(/^[^\t]*\t/, ""); print }'
}

# The structural facts, as `frontmatter=<state> fence=<state>`, from a single scan.
#
# The caller asked three separate questions before this existed, forking awk three times
# over one file while the comment above said the scan "is the only thing here that reads a
# file". The comment was right about the design and wrong about the call site.
blc_ledger_facts() {
  blc_ledger_scan "$1" | awk -F'\t' '
    $1 == "frontmatter" { fm = $2 }
    $1 == "fence"       { fe = $2 }
    $1 == "closed"      { cl = $2 }
    END { printf "frontmatter=%s fence=%s closed=%s\n", fm, fe, cl }
  '
}

# One structural fact by name. Kept for callers that genuinely want only one.
blc_ledger_structure() {
  blc_ledger_scan "$1" | blc_scan_field "$2"
}
