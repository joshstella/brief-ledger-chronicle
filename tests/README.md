# Tests

Coverage for `install.sh`. Run them:

```bash
bash tests/run.sh              # everything
bash tests/run.sh machine_     # only tests whose name contains "machine_"
```

Exit code is 0 when everything passes, 1 otherwise, so CI needs no extra wiring.

## Layout

```
tests/
  run.sh                  runner: discovers test_* functions, reports, sets exit code
  lib.sh                  assertions and fixtures
  test_args.sh            argument parsing, mode guards, the confirmation prompt
  test_hosts.sh           the two host layouts, --host validation, --yes
  test_project_mode.sh    what --target creates, and what it refuses to touch
  test_force.sh           --force replaces installer-owned copies, not briefs or the log
  test_install_log.sh     the append-only install log
  test_machine_mode.sh    --machine symlinking into $CLAUDE_HOME
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

`install.sh`'s project mode requires `git`, `gh`, `node`, `npm` and `claude` on
`PATH`. Only `git` is used by anything it actually does, and `claude` cannot be
installed on a CI runner at all — so `run.sh` puts inert stubs for the other four
on `PATH` and lets the real `git` through.

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
| `--force` overwrote `CLAUDE.md` | `force_does_not_overwrite_an_existing_claude_md` |
| `--force` skipped the process rules file | `force_replaces_cursor_process_rules` |
| `--force` rewrote a numbered brief | `force_leaves_an_existing_brief_untouched` |
| Hardcoded `0001-bootstrap/` restored | `project_install_over_existing_0001_creates_no_duplicate_serial` |
| Any numbered brief written by the installer | `project_writes_no_numbered_brief` |
| Machine mode clobbers a real file | `machine_refuses_to_clobber_a_real_file` |
| Dependency check removed | `project_missing_dependency_aborts_before_writing` |
| Self-install guard removed | `args_refuses_to_install_into_the_source_repo` |

One mutation initially read as a miss and was worth chasing: rewriting the log
header with `>` does not duplicate the header, it truncates the file. The header
count stayed at 1 while the install history was destroyed. The suite did catch it,
through the entry-count tests rather than the header test — but only because those
existed. The lesson is in the file: **assert on what must survive, not only on
what must not repeat.**

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
