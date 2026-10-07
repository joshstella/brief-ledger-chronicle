# tools/jira-csv.sh — one brief and its phases as a Jira Cloud CSV import (#0007 phase d).
#
# Helper and fixture names are prefixed jc_ / JC_ because run.sh sources every test file into
# one shell.

JC_IDENTITY='**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** me@x.org'
JC_TABLE_HEAD=('| id | label | status | branch |' '|---|---|---|---|')

jc_repo() {
  JC_DIR="$TMP/jc"
  mkdir -p "$JC_DIR/docs/blc/briefs"
}

# usage: jc_brief <folder> <title> <identity line> <status line> [ledger lines...]
# An empty status line writes no ledger.
jc_brief() {
  local dir="$JC_DIR/docs/blc/briefs/$1" status="$4"
  mkdir -p "$dir"
  printf '# %s\n\n%s\n' "$2" "$3" > "$dir/brief.md"
  shift 4
  [ -n "$status" ] || return 0
  printf '# Ledger\n\n`%s`\n\n' "$status" > "$dir/ledger.md"
  printf '%s\n' "$@" >> "$dir/ledger.md"
}

run_jc() {
  ( cd "$JC_DIR" && bash "$REPO_ROOT/tools/jira-csv.sh" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# A refusal exits 1 and writes nothing a caller's redirect could mistake for an export.
jc_refused() {
  assert_status 1
  [ ! -s "$OUT" ] || fail "a refusal wrote to stdout: $(head -2 "$OUT")"
  assert_err "$1"
}

# ── The export ───────────────────────────────────────────────────────────────

# Phases come out in status-line order, not table order, with the pointer dropped from
# each state. A skipped phase is a row: the Epic shows the whole plan.
test_jira_csv_writes_the_epic_then_each_phase() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY · **Owner:** o@x.org" \
    'blc/2 #0001 in-progress a:done(PR#1) b:skipped c:in-progress(brief/0001-c-x) d:pending' \
    "${JC_TABLE_HEAD[@]}" \
    '| c | the third | in-progress | — |' \
    '| a | the first | done | — |' \
    '| b | the second | skipped | — |' \
    '| `d — the fourth` | pending |'
  run_jc 1
  assert_status 0
  diff -u - "$OUT" <<'CSV' >"$TMP/diff.txt" || fail "export differs: $(cat "$TMP/diff.txt")"
"Summary","Work type","Work item ID","Parent","Description","Priority","Assignee","Reporter","Due Date","Labels","Components","Status"
"#0001 — The thing","Epic","1","","docs/blc/briefs/0001-a/brief.md","","o@x.org","me@x.org","","blc-0001","","in-progress"
"#0001/a — the first","Task","2","1","docs/blc/briefs/0001-a/ledger.md","","o@x.org","me@x.org","","blc-0001","","done"
"#0001/b — the second","Task","3","1","docs/blc/briefs/0001-a/ledger.md","","o@x.org","me@x.org","","blc-0001","","skipped"
"#0001/c — the third","Task","4","1","docs/blc/briefs/0001-a/ledger.md","","o@x.org","me@x.org","","blc-0001","","in-progress"
"#0001/d — the fourth","Task","5","1","docs/blc/briefs/0001-a/ledger.md","","o@x.org","me@x.org","","blc-0001","","pending"
CSV
}

test_jira_csv_assigns_the_author_when_there_is_no_owner() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  assert_status 0
  assert_out '"#0001 — The thing","Epic","1","","docs/blc/briefs/0001-a/brief.md","","me@x.org","me@x.org",'
  assert_out '"#0001/a — the first","Task","2","1","docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org",'
}

# The Epic's state drops its pointer too, or every finished brief is its own value to map.
test_jira_csv_drops_the_pointer_from_the_epic_state() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 done(PR#45) a:done(PR#44)' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | done | — |'
  run_jc 1
  assert_status 0
  assert_out '"#0001 — The thing","Epic","1","","docs/blc/briefs/0001-a/brief.md","","me@x.org","me@x.org","","blc-0001","","done"'
}

# A brief whose line names no phase yet is still an Epic.
test_jira_csv_exports_an_epic_with_no_phases() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  run_jc 1
  assert_status 0
  [ "$(wc -l < "$OUT")" -eq 2 ] || fail "expected the header and the Epic only: $(cat "$OUT")"
}

# A comma or a quote in a title must not split the field.
test_jira_csv_quotes_every_field_and_doubles_quotes() {
  jc_repo
  jc_brief 0001-a 'A "quoted", title' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | say "hi", then | pending | — |'
  run_jc 1
  assert_status 0
  assert_out '"#0001 — A ""quoted"", title","Epic","1",'
  assert_out '"#0001/a — say ""hi"", then","Task","2",'
}

# ── The descriptions ─────────────────────────────────────────────────────────

# usage: jc_append_brief <folder> <lines...> — append lines to the brief's text.
jc_append_brief() {
  local f="$JC_DIR/docs/blc/briefs/$1/brief.md"
  shift
  printf '%s\n' "$@" >> "$f"
}

# The claim ends at the next `## ` heading and keeps its own `###` subheadings. Blank lines at
# its ends go; the ones inside stay. A phase paragraph ends at the first blank line and loses its
# bold lead. A quote and a comma stay inside one field.
test_jira_csv_puts_the_claim_and_each_phase_paragraph_in_the_descriptions() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 in-progress a:in-progress b:pending' \
    "${JC_TABLE_HEAD[@]}" \
    '| a | the first | in-progress | — |' \
    '| b | the second | pending | — |' \
    '' \
    '**a — the first.** Do "this", then' \
    'that.' \
    '' \
    'Not part of a.' \
    '' \
    '**b — the second.**' \
    'Its text starts on the next line.'
  jc_append_brief 0001-a '' '## Ground' '' 'Not the claim.' '' '## The claim' '' \
    '**One line.**' '' '### A part' 'More.' '' '## Change' '' 'Not the claim either.'
  run_jc 1
  assert_status 0
  diff -u - "$OUT" <<'CSV' >"$TMP/diff.txt" || fail "export differs: $(cat "$TMP/diff.txt")"
"Summary","Work type","Work item ID","Parent","Description","Priority","Assignee","Reporter","Due Date","Labels","Components","Status"
"#0001 — The thing","Epic","1","","*One line.*

h3. A part
More.

docs/blc/briefs/0001-a/brief.md","","me@x.org","me@x.org","","blc-0001","","in-progress"
"#0001/a — the first","Task","2","1","Do ""this"", then that.

docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org","","blc-0001","","in-progress"
"#0001/b — the second","Task","3","1","Its text starts on the next line.

docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org","","blc-0001","","pending"
CSV
  [ ! -s "$ERR" ] || fail "expected no warning: $(cat "$ERR")"
}

# Jira's CSV importer reads wiki markup, not markdown. Each construct the record uses is here:
# italic before bold, because wiki bold is markdown italic; code that holds asterisks and dashes,
# which wiki would otherwise format; a double-backtick span; a link with italic text; wrapped
# lines joined; a list item and its continuation; a table with its separator row dropped; a
# heading; and a lone backtick and a spaced asterisk, which are text.
test_jira_csv_converts_the_text_to_wiki_markup() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  jc_append_brief 0001-a '' '## The claim' '' \
    '**Bold claim.** It has *italic*, `code with **stars**`, and `` `a — x` ``.' \
    'A wrapped' \
    'line with [a *link*](https://x.org/a_b) and `--max-age`.' \
    '' \
    '- item one' \
    '  continued' \
    '- item *two*' \
    '' \
    '| Phase | Work |' \
    '|---|---|' \
    '| `a — x` | Do **it** |' \
    '' \
    '### A part' \
    '2 * 3 and a lone ` tick.'
  run_jc 1
  assert_status 0
  diff -u - "$OUT" <<'CSV' >"$TMP/diff.txt" || fail "export differs: $(cat "$TMP/diff.txt")"
"Summary","Work type","Work item ID","Parent","Description","Priority","Assignee","Reporter","Due Date","Labels","Components","Status"
"#0001 — The thing","Epic","1","","*Bold claim.* It has _italic_, {{code with \*\*stars\*\*}}, and {{`a — x`}}. A wrapped line with [a _link_|https://x.org/a_b] and {{\-\-max\-age}}.

- item one continued
- item _two_

|| Phase || Work ||
| {{a — x}} | Do *it* |

h3. A part
2 * 3 and a lone ` tick.

docs/blc/briefs/0001-a/brief.md","","me@x.org","me@x.org","","blc-0001","","planned"
CSV
}

# A missing source is a thinner ticket, not a refusal, and the warning names what is missing.
test_jira_csv_warns_and_writes_the_path_when_a_source_is_missing() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending b:pending' \
    "${JC_TABLE_HEAD[@]}" \
    '| a | the first | pending | — |' \
    '| b | the second | pending | — |' \
    '' \
    '**b — the second.** Has text.'
  run_jc 1
  assert_status 0
  assert_out '"#0001 — The thing","Epic","1","","docs/blc/briefs/0001-a/brief.md","","me@x.org","me@x.org","","blc-0001","","planned"'
  assert_out '"#0001/a — the first","Task","2","1","docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org","","blc-0001","","pending"'
  assert_out '"#0001/b — the second","Task","3","1","Has text.'
  assert_err "has no '## The claim' text"
  assert_err '#0001/a: no paragraph'
  [ "$(wc -l < "$ERR")" -eq 2 ] || fail "expected two warnings: $(cat "$ERR")"
}

# A paragraph whose label is not the table's is not trusted as that phase's description.
test_jira_csv_warns_on_a_paragraph_with_another_label() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |' '' '**a — an old name.** Text.'
  run_jc 1
  assert_status 0
  assert_out '"#0001/a — the first","Task","2","1","docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org","","blc-0001","","pending"'
  assert_err "does not carry the label 'the first'"
}

# A label is free text. Passed to awk with -v, the `\t` here would become a tab, and the
# paragraph would not be found.
test_jira_csv_reads_a_label_with_a_backslash_as_written() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | split on \t | pending | — |' '' '**a — split on \t.** Text.'
  run_jc 1
  assert_status 0
  assert_out '"#0001/a — split on \t","Task","2","1","Text.'
}

test_jira_csv_refuses_two_paragraphs_for_one_phase() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |' '' \
    '**a — the first.** One.' '' '**a — the first.** Two.'
  run_jc 1
  jc_refused 'more than one paragraph'
}

test_jira_csv_refuses_two_claim_sections() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  jc_append_brief 0001-a '' '## The claim' 'One.' '' '## The claim' 'Two.'
  run_jc 1
  jc_refused "two '## The claim' sections"
}

test_jira_csv_takes_the_serial_in_any_of_its_spellings() {
  jc_repo
  jc_brief 0008-a 'Eight' "${JC_IDENTITY/0001/0008}" 'blc/2 #0008 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  local s
  for s in 8 0008 '#0008' 08; do
    run_jc "$s"
    assert_status 0
    assert_out '"#0008 — Eight","Epic",'
  done
}

# The template's "none yet" is not a key.
test_jira_csv_exports_a_blank_or_dash_jira_field() {
  jc_repo
  local v
  for v in '' '—'; do
    rm -rf "$JC_DIR/docs/blc/briefs/0001-a"
    jc_brief 0001-a 'The thing' "$JC_IDENTITY · **Jira:** $v · **Depends on:** —" \
      'blc/2 #0001 planned a:pending' "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
    run_jc 1
    assert_status 0
  done
}

# ── Refusals ─────────────────────────────────────────────────────────────────

test_jira_csv_refuses_a_brief_already_in_jira() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY · **Jira:** PROJ-12" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  jc_refused "already in Jira as PROJ-12"
}

test_jira_csv_refuses_an_assignee_that_is_not_one_email() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY · **Owner:** o@x.org, p@x.org" \
    'blc/2 #0001 planned a:pending' "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  jc_refused "Owner 'o@x.org, p@x.org' is not one email"
}

test_jira_csv_refuses_a_brief_with_no_owner_or_author() {
  jc_repo
  jc_brief 0001-a 'The thing' '**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z' \
    'blc/2 #0001 planned a:pending' "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  jc_refused "no Owner or Author"
}

test_jira_csv_refuses_a_blc1_ledger() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/1 #0001 in-progress 1:done 2:pending' \
    '| 1 | the first | done |'
  run_jc 1
  jc_refused "not blc/2"
}

test_jira_csv_refuses_a_numbered_phase_on_a_blc2_line() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 in-progress a:done 2:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | done | — |' '| 2 | the second | pending | — |'
  run_jc 1
  jc_refused "phase 2 is numbered"
}

# The gate would complain about `bc:`; an export that skipped it would drop a phase silently.
test_jira_csv_refuses_an_entry_that_is_not_a_phase() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 in-progress a:done bc:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | done | — |'
  run_jc 1
  jc_refused "entries that are not phases: bc:pending"
}

test_jira_csv_refuses_a_phase_with_no_label_or_two_rows() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 in-progress a:done b:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | done | — |'
  run_jc 1
  jc_refused "no row in docs/blc/briefs/0001-a/ledger.md gives phase b a label"
  printf '%s\n' '| a | again | done | — |' >> "$JC_DIR/docs/blc/briefs/0001-a/ledger.md"
  run_jc 1
  jc_refused "more than one row in docs/blc/briefs/0001-a/ledger.md could be phase a"
}

test_jira_csv_refuses_a_missing_ledger_or_status_line() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" ''
  run_jc 1
  jc_refused "#0001 has no ledger"
  printf '# Ledger\n\nNo line here.\n' > "$JC_DIR/docs/blc/briefs/0001-a/ledger.md"
  run_jc 1
  jc_refused "has no status line"
}

test_jira_csv_refuses_a_brief_with_no_title_or_identity_line() {
  jc_repo
  jc_brief 0001-a 'The thing' 'no identity here' 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  jc_refused "has no identity line"
  printf '%s\n' "$JC_IDENTITY" > "$JC_DIR/docs/blc/briefs/0001-a/brief.md"
  run_jc 1
  jc_refused "has no title line"
}

test_jira_csv_refuses_a_serial_it_cannot_resolve() {
  jc_repo
  mkdir -p "$JC_DIR/docs/blc/briefs/0002-a" "$JC_DIR/docs/blc/briefs/0002-b"
  run_jc 1
  jc_refused "no brief #0001 in docs/blc/briefs"
  run_jc 2
  jc_refused "#0002 names 2 brief folders"
  run_jc PROJ-1
  jc_refused "'PROJ-1' is not a serial"
  run_jc
  jc_refused "usage: tools/jira-csv.sh [--summary-file PATH] SERIAL"
}

# ── Standing on its own ──────────────────────────────────────────────────────

test_jira_csv_loads_the_libraries_it_reads() {
  local lib
  for lib in status-line identity-line phase-row; do
    assert_loads_library jira-csv.sh "$lib"
  done
}

# Run from a copy, so the libraries it finds are the ones beside it and not this checkout's.
test_jira_csv_runs_from_a_fixture_install() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  fixture_install_tool "$JC_DIR" jira-csv.sh
  ( cd "$JC_DIR" && ./tools/jira-csv.sh 1 ) >"$OUT" 2>"$ERR"
  assert_count 0 "$?" "jira-csv exit status from a fixture install"
  assert_out '"#0001/a — the first","Task","2","1","docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org","","blc-0001","","pending"'
}

# ── The columns Jira expects (#0027) ─────────────────────────────────────────

# Priority, Due Date and Components ship empty because the record holds nothing for them. The
# whole row is asserted, because an empty field is the one kind that disappears without trace:
# a dropped column shifts every field after it onto the wrong header, and the file still parses.
test_jira_csv_leaves_the_unsourced_columns_empty() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  assert_status 0
  assert_out '"#0001 — The thing","Epic","1","","docs/blc/briefs/0001-a/brief.md","","me@x.org","me@x.org","","blc-0001","","planned"'
  assert_out '"#0001/a — the first","Task","2","1","docs/blc/briefs/0001-a/ledger.md","","me@x.org","me@x.org","","blc-0001","","pending"'
}

# Assignee is the Owner and Reporter is the Author, so a brief one person filed and another owns
# exports as two different people.
test_jira_csv_reports_the_author_and_assigns_the_owner() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY · **Owner:** o@x.org" 'blc/2 #0001 planned a:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  assert_status 0
  assert_out '"docs/blc/briefs/0001-a/brief.md","","o@x.org","me@x.org",'
  assert_out '"docs/blc/briefs/0001-a/ledger.md","","o@x.org","me@x.org",'
  grep -q Reporter "$ERR" && fail "a well-formed Author warned: $(cat "$ERR")"
  return 0
}

# An Author that is not one email is a thinner ticket, not a refusal: Jira fills an empty
# Reporter with the importing user. A bad assignee still dies, and that difference is deliberate.
test_jira_csv_empties_the_reporter_when_the_author_is_not_an_email() {
  jc_repo
  jc_brief 0001-a 'The thing' \
    '**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Author:** nobody · **Owner:** o@x.org' \
    'blc/2 #0001 planned a:pending' "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  assert_status 0
  assert_out '"","o@x.org","","","blc-0001","","planned"'
  assert_err "Author 'nobody' is not one email"
}

test_jira_csv_empties_the_reporter_when_there_is_no_author() {
  jc_repo
  jc_brief 0001-a 'The thing' \
    '**Serial:** #0001 · **Created:** 2026-08-21T12:00:00Z · **Owner:** o@x.org' \
    'blc/2 #0001 planned a:pending' "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |'
  run_jc 1
  assert_status 0
  assert_out '"","o@x.org","","","blc-0001","","planned"'
  assert_err 'has no Author, so the Reporter column is empty'
}

# One label, the same on the Epic and on every Task, so one JQL term finds the whole import.
# The phase letter is not in it: a label per phase would fragment that search.
test_jira_csv_labels_every_row_with_the_serial_alone() {
  jc_repo
  jc_brief 0008-a 'Eight' "${JC_IDENTITY/0001/0008}" 'blc/2 #0008 planned a:pending b:pending' \
    "${JC_TABLE_HEAD[@]}" '| a | the first | pending | — |' '| b | the second | pending | — |'
  run_jc 8
  assert_status 0
  assert_count 3 "$(grep -c '"blc-0008",""' "$OUT")" 'rows labelled blc-0008'
  grep -q 'blc-0008-a\|blc-0008/a' "$OUT" && fail "a phase label would fragment the search: $(cat "$OUT")"
  return 0
}

# ── The summary a caller supplies (#0028) ────────────────────────────────────

# usage: jc_summary <lines...> — write a summary file and print its path.
jc_summary() {
  printf '%s\n' "$@" > "$TMP/summary.md"
  printf '%s' "$TMP/summary.md"
}

# The supplied text wins over the claim, and goes through the same markdown-to-wiki conversion.
# Both are present here so the precedence is proven, not inferred from a brief that has neither.
test_jira_csv_prefers_the_supplied_summary_over_the_claim() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  jc_append_brief 0001-a '' '## The claim' '' 'The claim text.'
  run_jc --summary-file "$(jc_summary 'A **supplied** summary.')" 1
  assert_status 0
  assert_out 'A *supplied* summary.'
  grep -q 'The claim text' "$OUT" && fail "the claim was used despite a summary file: $(cat "$OUT")"
  return 0
}

# Without the flag nothing changes, which is what lets a person keep running this by hand.
test_jira_csv_falls_back_to_the_claim_with_no_summary_file() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  jc_append_brief 0001-a '' '## The claim' '' 'The claim text.'
  run_jc 1
  assert_status 0
  assert_out 'The claim text.'
}

# A caller that named a file meant to use it. Falling back would put the wrong text on the Epic
# and say nothing about it.
test_jira_csv_refuses_a_summary_file_it_cannot_read() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  jc_append_brief 0001-a '' '## The claim' '' 'The claim text.'
  run_jc --summary-file "$TMP/no-such-file.md" 1
  jc_refused 'cannot read the summary file'
}

# Whitespace is not a summary. An empty file is the shape a failed generation leaves behind.
test_jira_csv_refuses_an_empty_summary_file() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  run_jc --summary-file "$(jc_summary '' '   ')" 1
  jc_refused 'is empty'
}

# Two claims are ambiguous only when the claim is what gets exported. Once the caller has said
# which text to use, the ambiguity is gone and the brief exports.
test_jira_csv_exports_two_claims_when_a_summary_is_supplied() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  jc_append_brief 0001-a '' '## The claim' '' 'One.' '' '## The claim' '' 'Two.'
  run_jc 1
  jc_refused 'two '\''## The claim'\'' sections'
  run_jc --summary-file "$(jc_summary 'The supplied one.')" 1
  assert_status 0
  assert_out 'The supplied one.'
}

test_jira_csv_takes_the_summary_flag_in_either_spelling_and_any_position() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  local f; f="$(jc_summary 'Supplied.')"
  run_jc 1 --summary-file "$f"
  assert_status 0
  assert_out 'Supplied.'
  run_jc "--summary-file=$f" 1
  assert_status 0
  assert_out 'Supplied.'
}

test_jira_csv_refuses_an_unknown_option_and_a_flag_with_no_path() {
  jc_repo
  jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
  run_jc --bogus 1
  jc_refused 'unknown option'
  run_jc 1 --summary-file
  assert_status 1
  assert_err 'usage: tools/jira-csv.sh'
}

# ── The skill that drives the tool (#0028) ───────────────────────────────────

JC_SKILL="$REPO_ROOT/skills/blc-export-to-jira/SKILL.md"

# The skill tells an agent to run the tool with a flag. Nothing makes the two agree, so a rename
# of the flag would leave the skill instructing a command that refuses. This runs every long
# option the skill names and asserts the tool knows it — the one half of a skill a test can check.
test_jira_csv_the_skill_names_only_flags_the_tool_accepts() {
  local flag found=0
  for flag in $(grep -o -- '--[a-z][a-z-]*' "$JC_SKILL" | sort -u); do
    found=1
    jc_repo
    jc_brief 0001-a 'The thing' "$JC_IDENTITY" 'blc/2 #0001 planned'
    run_jc "$flag" /dev/null 1
    grep -q "unknown option \`$flag\`" "$ERR" \
      && fail "the skill tells an agent to run $flag and the tool rejects it"
  done
  assert_count 1 "$found" 'long options named in the skill'
}

test_jira_csv_the_skill_runs_the_tool_it_documents() {
  assert_contains 'bash tools/jira-csv.sh --summary-file' "$JC_SKILL"
}

# The CSV and the summary are couriers, and the work tree is not where couriers wait. An
# untracked file in the root is how an unrelated 396-line document reached a commit in this
# repository once already, so the skill must not tell an agent to make one.
test_jira_csv_the_skill_writes_its_files_outside_the_repo() {
  local redirect
  redirect="$(grep -o '> *"\?[^"]*\.csv' "$JC_SKILL")"
  [ -n "$redirect" ] || fail "the skill no longer shows where the CSV goes"
  case "$redirect" in
    *mktemp*|*TMPDIR*|*/tmp/*) ;;
    *) fail "the skill writes the CSV into the work tree: $redirect" ;;
  esac
  assert_contains 'Write both files outside the repository' "$JC_SKILL"
}

# The decision that makes the summary safe to generate per export: it is not kept. A skill that
# lost this line would have an agent editing the record to match a board.
test_jira_csv_the_skill_says_the_summary_is_not_written_back() {
  assert_contains 'is not written back to the brief' "$JC_SKILL"
}
