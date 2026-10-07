# tools/check-architecture.sh — does every citation still point at code that exists (#0029 a).
#
# Helper and fixture names are prefixed arch_ / ARCH_ because run.sh sources every test file
# into one shell.

ARCH_DOC='docs/architecture/README.md'

# A work tree with two source files and an architecture document. Cited paths are relative to
# the repository root, so the fixture needs to be a repository.
arch_repo() {
  ARCH_DIR="$TMP/arch"
  mkdir -p "$ARCH_DIR/src" "$ARCH_DIR/docs/architecture"
  ( cd "$ARCH_DIR" && git init -q . )
  printf 'export class Router {}\n' > "$ARCH_DIR/src/router.ts"
  printf 'export function connect() {}\n' > "$ARCH_DIR/src/socket.ts"
}

# usage: arch_doc <lines...>
arch_doc() {
  printf '%s\n' "$@" > "$ARCH_DIR/$ARCH_DOC"
}

run_arch() {
  ( cd "$ARCH_DIR" && sh "$REPO_ROOT/tools/check-architecture.sh" "$@" ) >"$OUT" 2>"$ERR"
  LAST_STATUS=$?
}

# ── What it reports ──────────────────────────────────────────────────────────

test_arch_reports_when_every_citation_resolves() {
  arch_repo
  arch_doc '# Architecture' \
    'The router dispatches. <!-- cite: src/router.ts :: export class Router -->' \
    'The socket connects. <!-- cite: src/socket.ts :: export function connect -->'
  run_arch
  assert_status 0
  assert_out '2 citation(s), all resolve.'
}

test_arch_reports_a_citation_whose_file_is_gone() {
  arch_repo
  arch_doc '# Architecture' \
    'Still here. <!-- cite: src/router.ts :: export class Router -->' \
    'Long gone. <!-- cite: src/deleted.ts :: anything -->'
  run_arch
  assert_status 0
  assert_out '2 citation(s), 1 resolve, 1 rotted.'
  assert_out 'line 3  src/deleted.ts — file not found'
}

# The case a line-number citation could not catch without also crying on every refactor: the
# file is fine and the thing named in it is gone.
test_arch_reports_a_citation_whose_anchor_is_gone() {
  arch_repo
  arch_doc '# Architecture' \
    'Renamed since. <!-- cite: src/router.ts :: export class Dispatcher -->'
  run_arch
  assert_status 0
  assert_out 'line 2  src/router.ts :: export class Dispatcher — anchor not found'
}

# An anchor is literal text, matched with grep -F. A regular expression in one is a string to
# find, not a pattern to run, or a citation could pass by matching something it never named.
test_arch_matches_an_anchor_literally_and_not_as_a_pattern() {
  arch_repo
  arch_doc '# Architecture' \
    'Pattern, not text. <!-- cite: src/router.ts :: export .* Router -->'
  run_arch
  assert_status 0
  assert_out 'anchor not found'
}

test_arch_accepts_a_citation_with_no_anchor() {
  arch_repo
  arch_doc '# Architecture' 'It exists. <!-- cite: src/socket.ts -->'
  run_arch
  assert_status 0
  assert_out '1 citation(s), all resolve.'
}

test_arch_counts_two_citations_on_one_line() {
  arch_repo
  arch_doc '# Architecture' \
    'Both. <!-- cite: src/router.ts --> and <!-- cite: src/socket.ts -->'
  run_arch
  assert_status 0
  assert_out '2 citation(s), all resolve.'
}

# ── Report, do not gate (#0029 decision 8) ───────────────────────────────────

# The decision this tool turns on. A rotted citation says the document is behind the code, which
# is a thing to know and not a reason to stop a merge. An exit status of 1 here would make this
# a gate the first time anybody put it in CI.
test_arch_exits_zero_even_when_every_citation_has_rotted() {
  arch_repo
  arch_doc '# Architecture' \
    'Gone. <!-- cite: src/a.ts :: x -->' \
    'Also gone. <!-- cite: src/b.ts :: y -->'
  run_arch
  assert_status 0
  assert_out '2 citation(s), 0 resolve, 2 rotted.'
}

# ── When it cannot run ───────────────────────────────────────────────────────

test_arch_exits_one_when_the_document_is_missing() {
  arch_repo
  run_arch
  assert_status 1
  assert_err 'cannot read'
}

# A document nothing can check is not a passing document. Saying "all resolve" over zero
# citations would report success for the one case the whole tool exists to prevent.
test_arch_says_so_when_a_document_has_no_citations() {
  arch_repo
  arch_doc '# Architecture' 'The router dispatches requests.'
  run_arch
  assert_status 0
  assert_out 'No citations.'
  grep -q 'all resolve' "$OUT" && fail "an uncheckable document reported success: $(cat "$OUT")"
  return 0
}

# ── Where it reads from (#0024) ──────────────────────────────────────────────

# Cited paths are relative to the repository root. Run from a subdirectory they must still
# resolve, or the tool reports every citation rotted from the wrong directory.
test_arch_resolves_cited_paths_from_the_root_not_the_caller() {
  arch_repo
  arch_doc '# Architecture' 'The router. <!-- cite: src/router.ts :: export class Router -->'
  ( cd "$ARCH_DIR/src" && sh "$REPO_ROOT/tools/check-architecture.sh" ) >"$OUT" 2>"$ERR"
  assert_count 0 "$?" 'check-architecture exit status from a subdirectory'
  assert_out '1 citation(s), all resolve.'
}

test_arch_takes_an_explicit_document_relative_to_the_caller() {
  arch_repo
  mkdir -p "$ARCH_DIR/elsewhere"
  printf '%s\n' 'The socket. <!-- cite: src/socket.ts :: export function connect -->' \
    > "$ARCH_DIR/elsewhere/other.md"
  ( cd "$ARCH_DIR/elsewhere" && sh "$REPO_ROOT/tools/check-architecture.sh" other.md ) >"$OUT" 2>"$ERR"
  assert_count 0 "$?" 'check-architecture exit status with an explicit path'
  assert_out '1 citation(s), all resolve.'
}
