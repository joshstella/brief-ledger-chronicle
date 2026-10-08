# File modes in this repository's own tree.
#
# install.sh chmods every tool it places, so every assertion of the form "the
# installed tool is executable" passes whatever the source mode is. Five such
# assertions exist. All five stayed green while tools/open-briefs.sh sat at
# 100644 through two merges and their reviews: the suite was watching the copy,
# on the far side of the step that repairs it.
#
# The mode read here is the git index's, not the filesystem's. The index is
# what a fresh clone materializes, and a chmod that was never staged leaves
# every other checkout broken while looking repaired on the one that ran it.

# Sourced rather than invoked, so their mode carries no meaning.
# Matched by pattern, not listed, so adding a file to either place needs no edit here.
#
# tools/lib/ is exempt by path, not by inspecting the file. The directory is the
# declaration: putting code there is how an author says "this is sourced", and
# install.sh reads the same path the same way when it decides not to chmod it. The
# alternative considered was deriving it from a missing shebang, which infers the
# intent from a detail an author can omit by accident.
source_tree_is_sourced_not_invoked() {
  case "$1" in
    tests/lib.sh|tests/test_*.sh) return 0 ;;
    tools/lib/*.sh) return 0 ;;
    *) return 1 ;;
  esac
}

test_source_tree_every_invoked_script_is_executable_in_the_index() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }

  # Every field is local: run.sh sources all test files into one shell, so an
  # undeclared loop variable is a global. See "Helper names are shared across
  # every test file" in tests/README.md.
  local mode _sha _stage path checked=0 bad=""
  # `git ls-files -s` emits `<mode> <sha> <stage>\t<path>`. Read rather than a
  # hardcoded roster: a roster needs editing at the moment someone is adding a
  # tool and thinking about something else, which is when this last broke.
  while read -r mode _sha _stage path; do
    source_tree_is_sourced_not_invoked "$path" && continue
    checked=$((checked + 1))
    [ "$mode" = "100755" ] || bad="$bad $path($mode)"
  done < <(git -C "$REPO_ROOT" ls-files -s -- '*.sh')

  # A scan that matches nothing reports success, which is the failure mode this
  # whole file exists to name. Prove the scan looked at something.
  [ "$checked" -gt 0 ] || fail "the scan found no invoked scripts — it is broken, not clean"
  [ -z "$bad" ] || fail "not executable in the git index:$bad"
}

# A tool absent from install.sh's ship list installs nowhere. Nothing used to notice.
#
# The existing coverage names tools one at a time — `assert_file "$TARGET/tools/open-briefs.sh"`
# and four more like it — so it proves the named four and says nothing about a fifth. #0034
# added tools/next-serial.sh and both mutations of its ship-list entry, dropping it and
# keeping it, left the whole suite green. The tool would have shipped to no target at all.
#
# Derived from the tree, like the mode check above, and for the same reason: a hand-written
# roster needs editing at the moment someone is adding a tool and thinking about something
# else. tools/lib/ is included here even though it is exempt from the mode check — it is
# sourced rather than invoked, which changes its permissions and not whether it must arrive.
test_source_tree_every_tool_is_in_the_installer_ship_list() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }

  local path escaped checked=0 missing=""
  while read -r path; do
    checked=$((checked + 1))
    # Anchored to a whole line of the list, so a path named only in a comment or an echo does
    # not count as shipped. The list continues with ` \` and its last entry ends `; do`.
    escaped="$(printf '%s' "$path" | sed 's/\./\\./g')"
    grep -qE "^[[:space:]]*${escaped}([[:space:]]*\\\\|;[[:space:]]*do)[[:space:]]*$" \
      "$REPO_ROOT/install.sh" || missing="$missing $path"
  done < <(git -C "$REPO_ROOT" ls-files -- 'tools/*.sh')

  [ "$checked" -gt 0 ] || fail "the scan found no tools — it is broken, not clean"
  [ -z "$missing" ] || fail "install.sh never ships these, so they install nowhere:$missing"
}

# Every sed script the toolkit ships must parse on a POSIX sed, not only on GNU's.
#
# POSIX requires a `;` or a newline before the `}` that closes a `{...}` block. GNU sed accepts
# the block without one, and accepts it even under `--posix`. BSD sed, which macOS ships, does
# not. On 2026-10-08 `tools/orient.sh` ran its whole report on macOS and then exited 1 on
# `sed '1{/^# /d}'`, because `set -euo pipefail` turns the parse error into a failure. `orient`
# is step 1 of blc-start-brief, blc-next-brief-phase and blc-review-pr, so the toolkit failed
# at its own first gate on that platform.
#
# This is a static check and not a second interpreter. tests/run.sh runs a five-candidate awk
# matrix on the premise that one interpreter cannot see a portability bug; CI has no second sed
# and no macOS runner, so sixty-six sed invocations have only ever run against GNU. A macOS
# runner is the better answer and a larger change. This covers one shape, and says so.
#
# A regex interval — `\{10\}` — has the same closing brace and is correct. tools/orient.sh
# contains one, so a guard that could not tell them apart would be reverted the first time
# anybody ran it.
# usage: source_tree_sed_blocks_are_posix <line> — prints each offending sed script on the
# line, and nothing when the line is clean.
#
# The first version of this read the whole line and failed twice, which is why it reads the
# quoted script instead. `[ "$closed" -gt 0 ] && { echo; }` matched because `closed` contains
# the letters s-e-d, and `f() { ... | sed -n '...'; }` matched because the shell function's
# own brace was on the line. Both are shell, neither is a sed script.
#
# `sed` is therefore required to be a word, and only single-quoted strings on the line are
# examined. Every sed script this toolkit ships is single-quoted; a double-quoted one would be
# missed, and that limit is real rather than hidden.
source_tree_sed_blocks_are_posix() {
  printf '%s\n' "$1" | awk -v q="'" '
    # A `sed` word. Not `closed`, `parsed`, `used`.
    !/(^|[^[:alnum:]_])sed([^[:alnum:]_]|$)/ { next }
    {
      # Splitting on the quote makes the even-numbered fields the quoted scripts. The quote
      # arrives in a variable because a literal one cannot appear in this program.
      n = split($0, parts, q)
      for (i = 2; i <= n; i += 2) {
        s = parts[i]
        # `{d; }` is valid: POSIX wants a `;` or a newline before the brace, and the space
        # between them is not the problem. Collapsing it first stops a false positive.
        gsub(/[[:space:]]+\}/, "}", s)
        # A `}` whose preceding character is neither `;` nor a backslash. The backslash case
        # is a regex interval such as `\{10\}`, which is correct and which tools/orient.sh
        # already contains.
        if (s ~ /[^;\\]\}/) print s
      }
    }'
}

test_source_tree_every_shipped_sed_block_parses_on_a_posix_sed() {
  git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
    || { skip "not a git checkout"; return; }

  local path line n hit checked=0 bad=""
  while read -r path; do
    checked=$((checked + 1))
    n=0
    while IFS= read -r line; do
      n=$((n + 1))
      hit="$(source_tree_sed_blocks_are_posix "$line")"
      [ -n "$hit" ] && bad="$bad
    $path:$n: $hit"
    done < "$REPO_ROOT/$path"
  done < <(git -C "$REPO_ROOT" ls-files -- 'tools/*.sh' 'install.sh')

  [ "$checked" -gt 0 ] || fail "the scan found no shell to read — it is broken, not clean"
  [ -z "$bad" ] || fail "a POSIX sed rejects these; add a \`;\` before the \`}\`:$bad"
}

# The detector above has to tell three lookalikes apart, and each one is in the tree already.
# Fed by hand rather than by mutating real files, so a future edit to those files cannot
# quietly remove the case this proves.
test_source_tree_posix_sed_detector_tells_the_lookalikes_apart() {
  local flagged
  # usage: want_flagged <expected: yes|no> <description> <line>
  want_flagged() {
    flagged="$(source_tree_sed_blocks_are_posix "$3")"
    if [ "$1" = yes ]; then
      [ -n "$flagged" ] || fail "missed: $2 — $3"
    else
      [ -z "$flagged" ] || fail "false positive: $2 — $3 (flagged \`$flagged\`)"
    fi
  }

  want_flagged yes "the macOS bug itself" \
    "  sed '1{/^# /d}' \"\$AUTHORED\""
  want_flagged no "the same script, corrected" \
    "  sed '1{/^# /d;}' \"\$AUTHORED\""
  want_flagged no "a semicolon with a space before the brace" \
    "  sed '1{/^# /d; }' \"\$AUTHORED\""

  # A regex interval closes with \} and is correct. tools/orient.sh:147 has one.
  want_flagged no "a regex interval" \
    "  touched=\"\$(printf x | sed -n '1s/^[^ ]* \\(.\\{10\\}\\).*/\\1/p')\""

  # `closed` contains the letters s-e-d. The first version of this detector flagged it.
  want_flagged no "a shell brace group on a line mentioning closed" \
    "  [ \"\$closed\" -gt 0 ] && { echo; echo \"\$closed closed\"; }"

  # A shell function's own closing brace, on a line that really does call sed.
  want_flagged no "a shell function wrapping a real sed call" \
    "entry_pointer() { printf '%s' \"\$1\" | sed -n 's/.*(\\(.*\\))\$/\\1/p'; }"

  # Not orient-specific: any shipped file with the shape must be caught.
  want_flagged yes "the shape in some other tool" \
    "  printf '%s' \"\$x\" | sed '/^\$/{N;s/a/b/}'"

  # The three below are each proven load-bearing by mutation against the real tree, and are
  # repeated here by hand so that editing those files cannot quietly retire the case.

  # An awk block. No `sed` word, so the quoted script is never examined. Dropping the word
  # requirement flags tools/lib/status-line.sh.
  want_flagged no "an awk block with the same brace shape" \
    "  awk '\$1 == want { sub(/^[^\\t]*\\t/, \"\"); print}' \"\$f\""

  # A shell parameter expansion ends `:}`. Reading the whole line instead of the quoted script
  # flags tools/open-briefs.sh.
  want_flagged no "a parameter expansion beside a real sed call" \
    "entry_state() { printf '%s' \"\${1#*:}\" | sed 's/(.*//';}"

  # Prose in a comment is not a script. Reading the whole line flags the comment that explains
  # this very fix.
  want_flagged no "a comment that mentions a brace" \
    "  # The \`;\` before the \`}\` is required by POSIX and optional in GNU sed."

  unset -f want_flagged
  return 0
}
