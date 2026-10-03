# Tests

Coverage for `install.sh`, for `tools/validate-briefs.sh` (the Contract validator), for
`tools/open-briefs.sh` (the open-briefs query), and for
`skills/blc-chronicle/scripts/gather.sh` (the chronicle's source digest).
Run them:

```bash
bash tests/run.sh              # everything, once per awk on PATH
bash tests/run.sh machine_     # only tests whose name contains "machine_"
bash tests/run.sh --matrix-plan  # which interpreters would run, without running them
```

`bash tests/run.sh` is a **matrix**: it runs the whole suite once per `awk` implementation it
finds, and prints which ones it used and which candidates it did not find. Two names for one
implementation count once. A run with no `awk` at all exits 2 rather than reporting a pass over
an empty matrix.

For one fast pass under whatever `awk` comes first on `PATH`, set the re-entry flag the driver
uses and the matrix is skipped:

```bash
BLC_AWK_INNER=dev BLC_AWK_VERSION="$(awk --version </dev/null 2>&1 | head -1)" bash tests/run.sh
```

The redirects are not decoration. `2>&1` catches an `awk` that writes its version to stderr,
which would otherwise set the variable to an empty string and fail the run with a message about
the driver. `</dev/null` matters for an `awk` that does not know `--version` at all: it reads a
program from stdin instead, and the command hangs. The runner computes the version exactly this
way, and a value computed differently is a value the suite will reject.

That is a development convenience and not a matrix run — nothing prints a matrix summary, so
the output cannot be mistaken for one. `BLC_AWK_VERSION` must be the real version of that `awk`:
the suite checks itself against it, which is what stops a matrix run from naming an interpreter
it did not use.

Exit code is 0 when everything passes, 1 otherwise, and 2 when the suite could not run. CI needs
no extra wiring.

## What this suite claims about interpreters

**The suite runs under every `awk` it claims, names the ones it did not find, and states which
ones it used.** That is the whole claim, and it is what `docs/blc/contracts/README.md` criterion 1
requires before a `[judgment]` clause can be promoted to a `[defect]`.

The supported set is not written down in prose — not here, and not in the Contract README. It
is the candidate list `tests/run.sh` walks, and you read it by running:

```bash
bash tests/run.sh --matrix-plan
```

A sentence here listing the interpreters would be a second answer to a question that already
has one. Two answers drift, the prose becomes the stale one, and a reader trusts it — which is
the defect #0014 existed to remove and the reason this file does not restate the list.

Two properties hold the claim up, and both are tested rather than asserted:

- **Deleting a name from the candidate list fails a test.** The claim cannot be quietly
  narrowed to whatever already passes, which criterion 1 forbids in as many words.
- **An absent interpreter is named, never skipped in silence.** A local run with one `awk`
  and CI with four print different summaries, and that difference is the point. The moment
  both print the same line, this guard is gone.

A run with no `awk` at all exits 2. "No check exists" must not read as "the check passed".

### What it does not claim

**`bash` versions.** Every script here declares `#!/usr/bin/env bash`, so there is no `sh`
surface and no shell-family matrix to run — `dash`, `ksh` and `zsh` are not configurations this
toolkit can be in. The untested axis is bash *version*: macOS ships 3.2, this toolkit installs
into repositories on macOS, and nothing has ever run against a 3.2 binary. No bash 4 construct
appears anywhere — no `declare -A`, no `mapfile`, no `${var,,}` — which makes 3.2 likely fine
and unverified. Likely fine is not a claim, so it is not made.

## Layout

```
tests/
  run.sh                  runner: discovers test_* functions, reports, sets exit code
  lib.sh                  assertions and fixtures
  test_args.sh            argument parsing, mode guards, the confirmation prompt
  test_hosts.sh           the two host layouts, --host validation, --yes
  test_project_mode.sh    what --target creates, and what it refuses to touch
  test_replace.sh         replace-by-default for toolkit-owned paths, not briefs or the log
  test_prune.sh           stale skills/commands removed via the install log
  test_ownership_map.sh   one ownership map, five readers
  test_install_log.sh     the append-only install log
  test_machine_mode.sh    --machine symlinking into $CLAUDE_HOME
  test_briefs.sh          Contract clauses BRIEFS-1..8 (currently v1.3), plus this repo's own compliance
  test_brief_checks.sh    project checks in brief-checks/ (#0011)
  test_open_briefs.sh     every finding open-briefs.sh can emit, each provoked by a fixture
  test_detect_forge.sh    which forge hosts the remote, asked of stub gh and glab on a PATH
                          that holds nothing else (#0016)
  test_contract_ship.sh   what a target receives of the Contract and its validator
  test_gather.sh          the chronicle digest: both modes, its refusals, its ceiling
  test_source_tree.sh     file modes in this repo's own tree, which no install test can see
  test_phase_row.sh       the shared phase-row matcher, and that only one of it exists (#0014)
  test_status_line.sh     the shared status-line locator, and the shapes that separated its
                          two predecessors (#0014)
  test_interpreters.sh    the awk matrix: discovery, alias collapsing, run labelling, and the
                          refusal to pass over an empty matrix (#0015)
  test_clauses.sh         BRIEFS-9 and BRIEFS-10: that they report, that they never block,
                          and that the three readers of a ledger agree. Also holds the one
                          claim in the promotion criteria that can go stale (#0014)
  test_self_host.sh       this repo's own links give each host the skills a target install
                          gives it, read from --print-ownership, and each repo-only rule
                          binds both hosts (#0019)
```

A test is any shell function named `test_*`. The runner gives each one a fresh
temporary target project and a fresh `$CLAUDE_HOME`, then removes them afterwards.

## No framework, on purpose

The suite is plain bash with no dependencies. Three reasons:

1. **The repo has no dependencies today.** `bats` would be the first, and it would
   need installing on every machine and in CI before a single test could run.
2. **`install.sh` targets bash 3.2**, which is still the default `/bin/bash` on
   macOS. The tests run in the same environments the script claims to support.
3. **The assertions needed are trivial** — a file exists, content contains a
   string, an exit code matches. A framework would add vocabulary, not power.

If the suite ever needs parallelism, tagging, or richer reporting, port it. Until
then this costs nothing to run anywhere.

## Stubbed toolchain

`install.sh`'s project mode requires `git`, `gh` or `glab`, `node`, `npm` and
`claude` on `PATH`. Only `git` is used by anything it actually does, and `claude`
cannot be installed on a CI runner at all — so `run.sh` puts inert stubs for `gh`,
`node`, `npm` and `claude` on `PATH` and lets the real `git` through.

Tests that care about the dependency check build their own `PATH` instead, via
`run_install_with_path`. `test_project_missing_dependency_aborts_before_writing`
skips itself rather than lying if `claude` happens to resolve from `/usr/bin:/bin`
on the machine running it.

## Passing is not covering

A suite that goes green the moment it is written has proved nothing. Before
trusting a new test, break the behavior it guards and confirm it fails.

The original suite was validated against eight deliberate mutations of
`install.sh` — each caught by at least one test:

| Mutation | Caught by |
|---|---|
| Log header appended on every run | `log_header_is_written_only_once` |
| Log truncated on every run | `log_appends_one_entry_per_run` |
| `Target:` absolute path re-added to entries | `log_leaks_no_absolute_target_path` |
| `CLAUDE.md` copied unconditionally | `project_never_overwrites_an_existing_claude_md` |
| Install overwrote `CLAUDE.md` | `replace_does_not_overwrite_an_existing_claude_md` |
| Install skipped the process rules file | `replace_replaces_cursor_process_rules` |
| Install rewrote a numbered brief | `replace_leaves_an_existing_brief_untouched` |
| Hardcoded `0001-bootstrap/` restored | `project_install_over_existing_0001_creates_no_duplicate_serial` |
| Any numbered brief written by the installer | `project_writes_no_numbered_brief` |
| Machine mode clobbers a real file | `machine_refuses_to_clobber_a_real_file` |
| Dependency check removed | `project_missing_dependency_aborts_before_writing` |
| Self-install guard removed | `args_refuses_to_install_into_the_source_repo` |

`tools/validate-briefs.sh` was validated the same way, and it is the case where the
rule matters most. A validator exercised only against a compliant tree passes
identically when every check is replaced by `return 0`, so its green run carries no
information. Each clause therefore has a fixture that violates it. Neutering the
`defect` reporter fails eleven tests; restoring it returns the suite to green.

`gather.sh` was validated against five mutations. Reverting its `Depends on:` guard
fails seventeen of the twenty-three tests, which measures the bug rather than the
test: a brief with no dependency line ended the run, and almost every fixture has
one. Dropping the truncation notice, lowering the commit ceiling, forcing every
brief to report `executed`, and letting the fork scan run past its section each fail
exactly one test.

One mutation initially read as a miss and was worth chasing: rewriting the log
header with `>` does not duplicate the header, it truncates the file. The header
count stayed at 1 while the install history was destroyed. The suite did catch it,
through the entry-count tests rather than the header test — but only because those
existed. The lesson is in the file: **assert on what must survive, not only on
what must not repeat.**

## A refactor can remove a property nobody wrote down

Extracting the phase-row matcher into `tools/lib/phase-row.sh` (#0014 phase `a`) was
declared a no-behaviour-change change, and against the whole suite it was one: 283 tests
stayed green. It still removed something. Before the extraction `open-briefs.sh` had no
external dependency and ran from wherever it was reached. After it, the script located
`lib/` with `dirname "${BASH_SOURCE[0]}"` — the directory it was *reached* through — so
reaching it by a symlink, the ordinary way a tool lands on a `PATH`, made it exit 2
looking for a library beside the link.

No test covered it because no test had needed to: the property was free before, so nobody
had written it down. An independent review of the diff also passed it. It was found by
running the binary through a symlink on purpose.

`phase_row_open_briefs_runs_through_a_symlink` now pins it, and the mutation that proves
it — restoring the plain `dirname` — fails that one test and no other. **A property that
costs nothing to hold is the kind that disappears silently, because its test was never
written.**

## Two tools can disagree for a year with every test green

`open-briefs.sh` and `list-briefs.sh` both had to find a ledger's status line, and they did
it differently. One read positionally — title, then the next line. The other searched the
whole file. The divergence was deliberate and documented, and on all thirteen ledgers in
this repository the two returned identical results. No test written against real data could
have separated them.

They were not equivalent. Three shapes tell them apart, and each one is now a fixture in
`test_status_line.sh`: a blank line after the title, a status line further down the file,
and prose quoting an example status line above the real one. The positional reader reported
the first two as having no status line at all. The whole-file reader answered the third with
**the prose sentence**.

The last one was found by building a baseline before writing any code, and it reversed the
design: the phase had been planned around adopting the whole-file search, on the reasoning
that a permissive form can only widen what is found. A gate reading that sentence would
parse garbage phase ids and fail a correct ledger. Finding the wrong line is worse than
finding none. The shared locator searches the whole file **and** anchors the match.

A fourth shape survived even that, and review found it: an example at column 0 **inside a
code fence**. Anchoring defeats an example with prose in front of it; it does nothing about
one that is already at the start of its line. That is how `docs/blc/briefs/README.md` prints
the status line, so the first ledger to document its own format would have handed every
reader the example. The locator now tracks fences.

## A test can be named for the property it does not check

The agreement test this phase shipped ran both tools against every ledger and threw one
result away — `: "$in_open"` — leaving a single assertion that spoke only about
`list-briefs.sh`. Blinding `open-briefs.sh` completely failed eighteen other tests and left
the agreement test green.

Two things make this worth a heading rather than a bug fix. The first is that it is the same
defect as the section below, one phase later: a guard that names a property and does not
hold it. The second is the name. A later phase owing an agreement test would have found one
already written, with the right words on it, and had no reason to look inside. **A wrong
test is worse than a missing one**, because a missing one still reads as missing.

It was also written against the wrong corpus. Running over this repository's real ledgers
feels thorough and proves nothing here: those ledgers agreed under *both* old locators, which
is why the disagreement lasted. The rewrite uses the shapes that actually divide the two
readers, each planted in a real repo and read by both tools.

**That rewrite was also un-failable, and review proved it twice.** It checked each tool
against a private expectation rather than against the other one: `open-briefs.sh` must not
print `[no-line]`, `list-briefs.sh` must print `in-progress`. Giving `open-briefs.sh` a
rebuilt divergent locator left the whole suite green while the two tools reported *different
serials for the same ledger*. Making it exit 2 with no output passed as well, because
"does not contain `[no-line]`" is satisfied by printing nothing at all.

Two rules came out of it, and they are the reusable part:

- **Assert positively.** An absence check passes on silence, on a crash, and on an empty
  file. Every one of those is a tool that is not working.
- **Give the wrong answer somewhere to go.** Each fixture now holds a decoy status line —
  `#9999 done` — that a divergent reader takes. A reader that takes it reports a *finished*
  brief, so both sides say something specific and wrong, and the assertions fire. Without a
  decoy, a test can only distinguish "worked" from "produced nothing", which is the weaker
  half of what can go wrong.

## A lesson recorded under one tool's name does not reach the second

Phase `a` found that `open-briefs.sh` broke when reached through a symlink, fixed it, and
pinned it with `test_phase_row_open_briefs_runs_through_a_symlink`. Phase `b` copied that
walk into `list-briefs.sh` — with the comment explaining why it matters — and copied no
test. Replacing the whole walk with a plain `dirname` left all 303 tests green.

The write-up sat two headings up this file the whole time. It did not help, because the
protection was filed under the name of the first tool to need it. When a property moves to a
second implementation, the test has to move with it; the prose does not travel on its own.

## A guard that matches a comment guards nothing

`no_tool_rebuilds_the_locator` and `both_tools_read_the_library` both searched a tool's
source for a string. Both strings also appear in *comments* in the very files being checked
— comments explaining the library the guard exists to enforce. Removing the library from
`open-briefs.sh`'s load list entirely left both guards green, because the explanation of the
rule satisfied the test for the rule.

The guards now parse the bootstrap's load list and test membership in it, rather than asking
whether a name occurs anywhere in the file. A guard should read the mechanism, not the
documentation of the mechanism.

The fingerprint scan had the opposite failure at the same time. It had been narrowed to one
spelling of the locator — the `awk` form, with the slash escaped — when the library changed
shape. A rebuild written with `grep`, which is the likely rebuild, spells it without the
backslash and walked straight past. It now carries both spellings. **A guard for one
spelling of an idea is a guard for none.**

## A test can ask a real question in the wrong place

Globbing, relative paths, and `$PWD` are properties of the process's working directory. A
test that builds its decoys in one directory and runs the tool from another asks a genuine
question somewhere the answer cannot differ, and passes whatever the code does.

`a_status_line_does_not_glob_the_working_directory` created files named `q:done` and
`z:pending`, then ran `validate-briefs.sh` from the repository root. Deleting the `set -f`
that closes the hole left every test green. Run the tool from the directory that holds the
decoys, and assert the decoys exist before trusting the result.

The general form: when a test depends on ambient state — cwd, environment, locale, umask —
name where that state is set, and make the test set it.

## The interpreter you do not have is the one that breaks

The fence tracker was written with `{3,}` to mean three-or-more. Under `mawk` the locator
returned the fenced example it was written to skip — a wrong answer, not a missing one. The
fix was to spell it `` ````* ``, which both implementations read alike.

**The cause recorded here was wrong from the day it was written, and the truth is worse.** This
section used to
say `mawk` 1.3.4 "has no interval expressions and reads that literally". It has them. It
matches them **minimally**, where `gawk` matches maximally:

| pattern | input | `gawk` `RLENGTH` | `mawk` `RLENGTH` |
|---|---|---|---|
| `a{2,3}` | `aaaa` | 3 | 2 |
| `` `{3,} `` | six backticks | 6 | 3 |
| `` ```` `* `` | six backticks | 6 | 6 |

Read literally, `{3,}` would match nothing and the failure would be loud. Matching minimally
returns a *shorter* answer, so a fence tracker measuring its delimiter reads a six-backtick
fence as three and then closes it on the next run of three — with no error anywhere. The
misdiagnosis made the failure sound louder than it is, which is the direction that gets a
class of bug under-weighted.

Portable shell here means portable to the *implementations*, not just to POSIX on paper, and
"supports the feature" is not the same question as "agrees about the feature".

`tests/run.sh` now runs the whole suite once per `awk` on `PATH` and prints which ones it
used and which it did not find, so this is a guard rather than an instruction. An interpreter
that is not installed is named. A run with no `awk` at all exits 2 instead of reporting a pass
over an empty matrix.

The suite already contained the contradiction, pinned on one side.
`open-briefs_reports_no_line_on_unterminated_frontmatter` asserted that an unclosed `---`
block means no status line, while `list-briefs.sh` read the same fixture and reported its
status as `done`. One stray `---` hid a ledger's entire status from one tool and not the
other, and a passing test said that was correct.

**A test that pins one side of a disagreement makes the disagreement look like a decision.**

## A green run can be evidence of a run that did not happen

The matrix was built in two halves: a planner that decides which interpreters run, and a driver
that runs them. The planner got tests, because a planner is easy to test — it prints, and a test
reads what it printed. The driver got none, because testing it needs a `PATH` the test controls
rather than the machine's.

Three separate one-line mutations to the driver then left the matrix fully green: ignoring a
failing interpreter, deleting the refusal on an empty matrix, and pointing every shim at the
first entry. That last one ran `gawk` twice and printed `run 2/2: mawk`.

**No assertion outside a run can see which binary the run used.** The driver installs a shim
named `awk` at the front of the inner run's `PATH`; from outside, a correct shim and a wrong one
produce the same output. So the driver hands the inner run the version it announced, and the
inner run checks the `awk` it actually got against it. The check lives where the evidence is.

Two more things had to change to make those tests mean anything:

- **The plan-report-refuse sequence was written twice**, once per entry point. A guard reachable
  by two code paths, with the suite proving neither, survives a mutation that deletes it from
  one — the other still prints the same refusal. It is one function now.
- **`tests/run.sh` had lost its `FILTER` assignment.** Unset, the selection pattern `*"$FILTER"*`
  becomes `**`, so every inner run ran the whole suite and the new driver tests spawned matrices
  of matrices until the machine ran out of processes. Nothing failed. The suite was green the
  whole way down.

A test harness is code, and the parts of it that are awkward to test are where its defects are.

## A guard whose pattern stops matching its own target

The same phase shipped a test whose entire job was to fail if any tool re-derived the
shared matcher. It could not fail. The fingerprint was written as the ERE `~\*\`\?`,
which asks for `` ~*`? ``; the source it searches for contains `` ~*\`? ``, with a
backslash before the backtick because the backtick is escaped inside a double-quoted
shell string. It matched nothing in the repository — not a copy, not the library it was
guarding, nothing.

A verbatim copy of the whole matcher, planted at `tools/copycat.sh`, passed it. The PR
body called it "the test that matters" and the ledger offered it as the compensating
control for deferring half the phase's deliverable. It was a tautology, and it was found
by review, not by the suite.

The pattern is now a literal searched with `grep -F`, and two positive controls sit in
front of the guard: one asserts the fingerprint still appears in the library, the other
plants a copy in a temporary directory and requires the scan to find it. Rotting the
fingerprint back to the broken ERE fails both and leaves the guard itself green — which
is the point, because the guard alone could never have told you.

**A scan that matches nothing reports success.** This file already says that about
`checked > 0` in `test_source_tree.sh`. The lesson did not transfer to the next scan
written, three days later, by someone who had read it. Guard the search itself, not only
the thing being searched for.

## An assertion downstream of a repair cannot see the break

`install.sh` runs `chmod +x` on every tool it places. Five tests assert that an
installed tool is executable. All five read the copy on the far side of that
`chmod`, so none of them can fail for a source file whose mode is wrong.

`tools/open-briefs.sh` went to mode `100644` in `f0dc92d`, stayed there through
the next merge and both PR reviews, and was found by hand in a `git pull` summary.
The suite was green throughout. `test_source_tree.sh` now asserts the mode in this
repository's own tree, and the mutation that proves it — `git update-index
--chmod=-x tools/open-briefs.sh` — fails that one test while all 41 install and
ship tests stay green. That green is the finding, not a side note.

The assertion reads the **git index**, not the filesystem. The index is what a
fresh clone materializes. A `chmod` that was never staged repairs one working
copy and leaves every other one broken.

**Assert on the artifact you ship, not on a copy something else has already
normalized.**

## Helper names are shared across every test file

The runner sources all `test_*.sh` files into one shell, so helpers are global. Two
files defining `add_ledger` do not collide loudly — the last one sourced wins, and
the other file's tests silently run against fixtures they did not write.

This happened while writing `test_gather.sh`: its `make_repo`, `add_brief` and
`add_ledger` were overridden by the identically named helpers in
`test_open_briefs.sh`, which sorts later. Three tests failed with assertions about
missing content, pointing at the script under test rather than at the fixture that
was never built. The script was fine.

Prefix helpers with the file's subject — `gather_repo`, `gather_brief` — so a
collision is impossible rather than merely unlikely. Assertions in `lib.sh` are
shared on purpose and stay unprefixed.

## Fixture commits need a real change

`git commit` on an unchanged tree fails, and under a helper that discards output it
fails quietly. A loop meant to build 65 commits built one, and the test that needed
them read as a bug in the ceiling logic. If a fixture wants N commits, it has to
write something N times.

## Negative assertions need a success assertion beside them

`test_host_cursor_creates_no_claude_directory` asserts that a Cursor install leaves no
`.claude/` behind. Written with only that assertion, it passed a mutation that forced the
Claude-only settings step to run under Cursor — because `.claude/` is never scaffolded on
that host, the `cp` failed, `set -e` aborted the install, and "no `.claude/`" became
trivially true. **The test was satisfied by the installer crashing.**

Adding `assert_status 0` fixed it. Any test built only from `assert_no_file` /
`assert_no_dir` has this hole: it cannot tell "the code correctly did nothing" from "the
code never ran". Assert that the thing succeeded, then assert what it did not do.

## A test must not be able to damage the repo it tests

`test_args_refuses_to_install_into_the_source_repo` exercises the guard that stops
the installer writing into its own checkout. The obvious way to write it — aim the
installer at `$REPO_ROOT` — makes the test dangerous in exactly the case it exists
for: if the guard regresses, the installer writes into the working tree, and the
test reports the bug by causing the damage.

It runs against a throwaway copy instead (`clone_installer_to_tmp`), so a regression
lands in `$TMP`. Confirmed by removing the guard: the test fails with four
assertions and the writes land on the copy.

Any future test that points a mutating command at a real path deserves the same
treatment.
