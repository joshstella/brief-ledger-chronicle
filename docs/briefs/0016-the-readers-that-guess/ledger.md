# Ledger — #0016 The readers that guess

`blc/2 #0016 in-progress a:done(PR#70) b:done(PR#71) c:done(PR#72) d:in-progress(brief/0016-d-the-forge-in-prose)`

**Brief:** `docs/briefs/0016-the-readers-that-guess/brief.md`
**Started:** 2026-09-30
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the identity reader | done (PR#70) | — |
| b | the pointer vocabulary | done (PR#71) | — |
| c | the forge probe | done (PR#72) | — |
| d | the forge in prose | in-progress | `brief/0016-d-the-forge-in-prose` |

The phases follow the seam the brief names in Tension: `a` is the reader half, `b` is where the
two halves meet, and `c` and `d` are the forge half.

**a — the identity reader.** A tolerant shared reader in `tools/lib/`. It locates the identity
line and returns one field's value, ending at the next `·` (decisions 2, 7, 8).
`validate-briefs.sh` and `list-briefs.sh` both use it, and a guard proves no local re-derivation
survives. `validate-briefs.sh` is the only other reader in the tree. Two tests from #0007
phase `a` pin the greedy read this phase removes, and they have to be inverted, not deleted:
`a_hash_after_depends_on_becomes_a_dependency` and
`an_existing_serial_after_depends_on_is_swallowed_in_silence`. The README paragraph "`Depends on`
goes last" keeps its rule (decision 5) and loses its loud-and-quiet account, which stops being
true. The PR must state that `BRIEFS-6` examines less than it did (decision 8).

**b — the pointer vocabulary.** `open-briefs.sh` learns `!123` as a merge-request token
(decision 3). The parser checks every field it does not recognise instead of stopping at the
first one. A field that is not a PR, an MR or a commit and does not resolve as a branch is
reported as unrecognised, not as a missing branch (decision 4). The record format in
`docs/briefs/README.md` gains the token. No forge is called yet: `!123` is parsed and shown, and
its state is reported as not checked.

**c — the forge probe.** Detection per decision 9: take the remote's host, and ask
`gh auth status --hostname <host>` and `glab auth status --hostname <host>`. Both report
through the exit code, so nothing parses their output. `open-briefs.sh` then looks up PR state
through `gh` or MR state through `glab`. If neither matches, the tool says it did not check,
as it already does when `gh` is absent. Tests use stub CLIs on `PATH`, the technique from
#0015.

**d — the forge in prose.** `blc-commit-push-pr`, `blc-review-pr` and `blc-next-brief-phase`
stop naming one forge. `README.md`, `docs/slides-process-overview.md` and the `install.sh`
dependency hint list `glab` beside `gh`. How a skill learns which forge it is on is decision 11,
below.

## Dependency structure

`a` is independent of everything else. It touches the identity line; `b`, `c` and `d` never read
it.

`b → c → d` is a strict chain. `c` needs `b`'s token before there is an MR to look up, and `d`
needs `c`'s detector before a skill can be told which CLI to use.

So there are two tracks: `a` alone, and `b → c → d`. **They run one after the other: `a` first,
then the chain.** Decided 2026-09-30. The two tracks do not depend on each other, but running
them at once would conflict on the status line every time; see the complications.

## Open decisions

The brief settled nine at filing. These three came from reading the code and block the phase
named.

| # | decision | blocks |
|---|---|---|
| 10 | **Settled 2026-09-30: it moves.** `BRIEFS-5` checks the shared reader's field values. | `a` |
| 11 | **Settled 2026-10-01: a program.** `tools/detect-forge.sh` prints `github` or `gitlab`; `open-briefs.sh` and the skills all run it. | `c` |
| 12 | **Settled 2026-10-01: normalised** to `open`, `merged`, `closed`. | `c` |
| 13 | **Settled 2026-09-30.** A field that is no fixed token and no existing branch is reported without a cause: "not a PR or MR, and no branch by that name exists". | `b` |
| 14 | **Settled 2026-09-30.** Only open phases' pointers are read. | `b` |
| 15 | **Settled 2026-09-30, then reversed.** `PR 14` was to be read as a PR. It cannot arrive; see below. | `b` |
| 16 | **Settled 2026-09-30.** Every existing branch in a pointer is measured, one line each. | `b` |
| 17 | **Settled 2026-09-30.** A pointer cut short by a space is reported, not read in part. | `b` |
| 18 | **Settled 2026-10-01.** A `deferred` or `skipped` reason goes in the phase table, never the pointer. | `b` |

**10 — settled: move.** One reader means one reader, including for the `[defect]` clause.
"One reader" argues for moving the checks. `BRIEFS-5` is a `[defect]` clause, and moving
it changes a gate. The existing negative fixtures in `tests/test_briefs.sh` pin every current
`BRIEFS-5` failure, so a move that changes behaviour will fail them. That makes the move safe to
attempt, not free.

**11.** A skill is an instruction to an agent and cannot source a library. Without a program,
every skill that needs the forge describes detection in prose. That is a second detector, and
"a skill guard is not a check" applies. A program is a new tool, and the #0007 re-plan counted
four coordinated `install.sh` edits for each one: roster, prune list, summary, and skill list.

**12.** `gh` reports `OPEN`/`MERGED`/`CLOSED`. `glab` reports `opened`/`merged`/`closed`.
`open-briefs.sh` output is read by people, and two spellings of one state in one report is
noise.

**13.** A deleted branch and a tracker key look the same to the parser. A deleted branch is the
stale pointer the tool exists to catch, so calling every unknown field "unrecognised" would hide
it, and calling it "a missing branch" is the old guess. The finding states what was checked.

**14.** A closed phase's pointer is never resolved, so the tool never guesses about it, and
decision 4 has nothing to correct there.

**15 — reversed, and 17.** Decision 15 was settled on a false premise. `blc_status_phase_entries`
splits the status line on spaces, inside the parentheses too, so `PR 14` reaches the parser as
`PR`. A space anywhere in an open phase's pointer, as in `(feature/x, PR#14)`, cut the pointer
and made the tool say "no branch recorded" for a phase that had one. No ledger here had that
shape. Decision 17 chose to report the cut in `open-briefs.sh` and to keep the shared tokenizer,
because `BRIEFS-9` reads it and changing it is a gate change. `commit <sha>` holds a space too,
so it is written only on closed phases, which nothing reads.

## Complications

**Parallel tracks and one status line.** Every phase branch edits the ledger's status line. The
previous phase is marked `done` on the next phase's branch. Branches running at the same time
will therefore conflict on that one line every time. The conflicts are trivial, but they are
certain. Running `a` first, alone, costs one PR of calendar time and avoids them.

**This brief rewrites #0007's work, and #0007 is still open.** #0007 phase `a` wrote the README
paragraph and the two tests that phase `a` here changes. #0007 phase `b` moves the `Jira:`
append before `Depends on` for a reason that stops being true once this brief's phase `a` lands.
The move is still right, because decision 5 keeps the rule as a backstop. Its stated reason will
need correcting in #0007's ledger when that phase is planned.

**#0007 phase `c` should read `Owner:` through this brief's reader.** It is a new reader of an
identity-line field. If it lands first, it lands as a third local parser, which is exactly the
drift this brief exists to close. Phase `a` here should land before #0007 phase `c` starts.

**Checked 2026-10-01: `auth status --hostname` asks the server.** With `gh` 2.97.0, the probe
for `github.com` exits 0 with the network and 1 with the GitHub API blocked. `glab` 1.113.0 calls
`GET /api/v4/user`; with no valid token for `gitlab.com` it reported `401 Unauthorized` and
exited 1. So an expired token, no network and no account all read as "no match", and the tool
says it did not check (decision 9). No other fallback is needed. One probe took 0.27s. A
successful `glab` lookup was not observed, because no valid GitLab token exists on this machine;
the tests use stub CLIs.

## Phase a — what it does

`tools/lib/identity-line.sh` has two functions. `blc_identity_line` returns the first line that
begins `**Serial:**`. `blc_identity_field` returns one field's value, from its label to the next
`·`, with spaces trimmed. The first occurrence of a label wins. It returns 1 when the label is
absent and 0 when the value is blank, because `BRIEFS-5` reports only the first. Labels it does
not know are ignored (decision 2).

`validate-briefs.sh` reads all four `BRIEFS-5` fields and the `BRIEFS-6` dependencies through
it (decision 10). `list-briefs.sh` reads its dependency column through it. `install.sh` ships it.

`list-briefs.sh` now shows `—` for a brief with no `**Serial:**` line, even if a `Depends on`
appears elsewhere in the file (decision 7). The chronicle's table comes from `list-briefs.sh`,
so it changes the same way. Such a brief already fails `BRIEFS-5` with "no identity line". The
`tests/test_gather.sh` fixture that wrote a bare `Depends on` line now writes an identity line.

**What changed at the gate.** Decision 10 moved `BRIEFS-5` on the condition that it did not
change. Two rules of the shared reader change it anyway: every field ends at `·`, which is
decision 8 applied to every field, and the first occurrence of a label wins, which this phase
chose. So the rule chosen on 2026-09-30 is: nothing that failed may now pass, and each stricter
case is stated. The old and new validators were run on 72
unusual identity lines. Nine verdicts differ, and none of the 16 briefs here has any of these
shapes.

- `BRIEFS-5` is stricter in four cases, all accepted:
  - a second `Created` field after a bad one;
  - a second `Author` field after a bad one;
  - a `·` inside `Author`, in two positions.
- `BRIEFS-6` examines less (decision 8). A `#NNNN` after the `·` that ends `Depends on` is not a
  dependency. This covers `ticket #9999` in a later field, `#0002 · #0007` written with `·`
  instead of a comma, and a second `Depends on` label. Four cases now pass that blocked before.
- `BRIEFS-6` is stricter in one case: with two `Depends on` labels, the first is read, not the
  last.

The reader trims spaces only. Trimming tabs as well would let a tab after `Serial` or `Created`
pass, and both failed before. A tab after `Author` passed before and still passes; that is older
looseness, not this phase's.

The two #0007 tests that pinned the old read are inverted, not deleted, as
`a_hash_after_depends_on_is_not_a_dependency` and
`an_existing_serial_after_depends_on_is_not_swallowed`. Each has a control that proves every
serial inside the field is still read. On the 16 briefs in this repository, both tools print
byte-identical output before and after.

**Proof.** `tests/test_identity_line.sh` holds 17 tests: the reader, both tools on the two shapes
that used to split them, both tools loading the library, and a guard against a local rebuild.
The guard fingerprints four spellings of each of the four labels: regex-escaped, bracketed, and
followed directly by a closing single or double quote. It has a positive control and planted
rebuilds. It is a fingerprint, not a parser. It misses other spellings, such as
`awk -F'Depends on:'` or a quoted label with a space before the closing quote. `tests/test_briefs.sh`
gains a fixture for each `BRIEFS-5` case above, for `**Serial:** 0001` without its `#`, for the
`Author` anchor, and for the digit cut in `#0001x`.

Fifteen mutants were run, and all were killed:

- in the reader: the field end, the locator, blank against missing, trimming, trimming tabs
  too;
- in the validator: the `#` rule, the `Author` anchor, the digit cut, a greedy read, a read of
  only the first dependency, the library load;
- elsewhere: the old `list-briefs.sh` sed, the install roster, emptied fingerprints, and
  fingerprints for `Serial` only.

The roster mutant is killed by `test_ship_places_a_validator_that_runs`. The filter
`test_contract_ship` selects no tests, because that file's functions are named `test_ship_*`.

## Phase b — what it does

`open-briefs.sh` classifies every field of an open phase's pointer: `PR#N`, `!N` (a GitLab merge
request, decision 3), or an existing branch, where `N` is digits. Any other non-empty field is
reported (decisions 4, 13), so an unknown field no longer hides the branch after it or vanishes behind
the branch before it. Every existing branch is measured (decision 16). Beside a branch, `!N` is
shown as `MR !N (state not checked)`; no forge is asked until phase `c`. A pointer cut short by
a space is reported (decision 17). Fields are not globbed. `docs/briefs/README.md` states the
pointer format and where a reason goes (decision 18), and its tracker section no longer
describes the guess.

**Known and left as they are**, by choice on 2026-10-01, after review:

- Only the first PR and the first MR in a pointer are shown; a second is dropped.
- A pointer with a PR or MR and no branch says "no branch recorded" and does not show them.
- The cut check says "cut at a space" for `(x)y`, which has no space. A space before the `(`
  still gives "no branch recorded".
- A branch listed twice is measured twice.
- `!0` is read as a merge request, and `PR#0` is looked up as a PR.
- An empty field, as in `(feature/x,,)`, is dropped without a finding.
- A branch whose name begins with `PR#` or `!` is never measured. If it is not a well-formed
  token, it is reported as "no branch by that name exists", though the branch exists.

**What changed in the output.** A branch that does not exist used to read "branch 'x' does not
exist". It now reads "'x' is not a PR or MR, and no branch by that name exists". On this
repository's ledgers the output is unchanged.

**Proof.** `tests/test_open_briefs.sh` gains twelve tests. PR lookups go through a `gh` stub
first on `PATH`, which records its calls. `/usr/bin/gh` exists here and on GitHub's Ubuntu
runners, so the file's old claim that its short `PATH` hides `gh` was false; it did no harm only
because no fixture put a PR on an open phase. Twelve mutants were run, and all were killed. One
first survived because its fixture had a space in the pointer and tested nothing; the fixture
was fixed.

Review found two faults, both fixed: a pointer field was globbed, so `(*)` reported the working
directory's file names, and `PR#` took any suffix, so `PR#abc` reached `gh` as a PR number and
`PR#--web` as an option. The old parser had both. Each fix has a test that fails without it.

## Phase c — what it does

`tools/detect-forge.sh [remote]` prints `github` or `gitlab` for the remote's host (decision 11).
With no argument it reads `origin`. When there is no `origin` and exactly one remote, it reads
that remote, because `gh` found a repository through any remote before this phase. It does not
choose among two or more. It reads the host from a `scheme://user@host:port/path` URL or from
an scp-style `user@host:path`, and lowercases it. A path that begins with `/`, `./` or `../`,
and a `file:///` URL, have no host. It then asks both CLIs `auth status --hostname <host>`. When exactly one accepts, it prints that
forge and exits 0. When neither accepts, when both accept, or when the remote has no host, it
prints nothing on stdout, gives the reason on stderr and exits 1. It exits 2 outside a git
repository or when the remote does not exist. `install.sh` ships it beside `open-briefs.sh`.

`open-briefs.sh` runs the detector only when an open phase has a PR or an MR, and only once per
run. On GitHub it asks `gh` about `PR#N`. On GitLab it asks `glab` about `!N`. It does not ask
one forge about the other's number: it says "state not checked: the remote is on GitLab" (or
GitHub). With no forge detected it says "state not checked: no forge detected". States are
normalised to `open`, `merged` and `closed` (decision 12); an empty answer reads `unknown`, and
any other word is shown in lower case. A missing detector is a broken install, so
`open-briefs.sh` exits 2 and names it.

**What changed in the output.** A PR state was `gh`'s word, `OPEN` or `MERGED`. It is now
`open` or `merged`. "(state not checked: no gh)" is now "(state not checked: no forge
detected)". An `!N` beside a branch on a GitLab remote now has a state. On a remote that no CLI
accepts, a PR is no longer looked up through whatever `gh` is installed.

**Known and left as they are**, by choice on 2026-10-01, after review:

- A relative path with a colon, such as `sub/team:r.git`, is read as the host `sub/team`, and
  `file://localhost/...` as the host `localhost`. Git reads both as local. No CLI accepts such a
  host, so the result is still "no forge detected", one round trip later.
- A bracketed IPv6 host, such as `ssh://git@[::1]/r.git`, is not read.
- `open-briefs.sh` drops the detector's reason. "Both CLIs accept the host" also reads "no forge
  detected", because decision 9 asks only that the tool say it did not check.

**Proof.** `tests/test_detect_forge.sh` holds 13 tests. Each runs with a `PATH` that holds only
links to `git` and `tr` and the stub CLIs the test names, so "not installed" can be tested on a
machine with `/usr/bin/gh`. `tests/test_open_briefs.sh` replaces its `gh` stub with a `gh` and a
`glab` that accept one forge and record every call. It has 9 new tests and 2 fewer old ones, 7
more in all.
`test_ship_places_an_open_briefs_query_that_runs` runs the installed `open-briefs.sh` in a fresh
target. `fixture_install_tool` copies the detector when it installs `open-briefs.sh`.

Twenty-two mutants were run, and all were killed:

- in the detector: both accepting treated as a match, `glab` not asked once `gh` accepts, the
  host not lowercased, URL user or port kept, scp user kept, a local path with a colon read as
  a host, a missing remote exiting 1, the probe not naming the host, no fallback to the only
  remote, a fallback to the first of many, a fallback that replaces a named remote;
- in `open-briefs.sh`: detection on every lookup, detection with nothing to look up, PR or MR
  state not normalised, `opened` not mapped, an empty state not called `unknown`, an MR asked of
  `gh`, a PR asked of `glab`, a PR asked on GitLab, the missing-detector check removed.

Three first survived. The MR test matched `open` as a substring of `opened`, no test gave an
empty state, and no local path held a colon. Each test was fixed or added. The roster mutant is
killed by the ship test above.
