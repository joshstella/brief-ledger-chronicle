# The install that cannot tell it is behind

**Created:** 2026-10-13T18:14:59Z · **Author:** josh.stella@gmail.com
**Depends on:** —

## The finding

`orient` tells a person when their **checkout** is behind its upstream. It is one of the
first lines it prints, and the skill says to fetch and run again before trusting the rest.

It says nothing about whether the **installed toolkit** is behind. In a target repository it
already reads `docs/blc/install-log/install-log.md`, which records the version that wrote
every toolkit-owned file. It reports what that install wrote. It does not report that a newer
one exists.

## What that cost

On 2026-10-08 a contributor reported that `blc-orient` exited 1 on macOS. The cause was one
missing `;` in a sed script. #0035 fixed it and shipped a guard for the shape, closing as
`df33e4d` — PR #148, the same day.

On 2026-10-13 the same contributor reported the same failure. Their installed toolkit was
`227+6db002a`. That is `6db002a`, the #0034 closeout, PR #147 — **the commit immediately
before the fix.** Nothing in their repository said so. The failure was diagnosed from
scratch a second time, by a second reader, five days after it had been fixed.

**Pulling would not have helped them.** `tools/orient.sh` is toolkit-owned: an install writes
it, and the install is the only thing that replaces it. A person who knows a fix exists, who
updates their repository, and who runs the command again, still gets the old program. The
obvious action is the wrong one, and nothing says so.

## Why this looks cheap

The version is already ordered. `227` is `git rev-list --count` at that commit; this
checkout is at `232`. Comparing installs is an integer comparison, not version parsing.

## The hard part

**Against what?** A target repository holds no copy of the toolkit source, so "what is
available" has to come from somewhere, and nothing in `tools/` has ever made an HTTP call —
no `curl`, no `wget`, no URL. The Jira work hit the same wall and the answer there was to put
the network in the skill and keep the decision in a tool, where a test can reach it. The same
split probably applies, but it is a decision and not an obvious one.

## Open

- **Where does the available version come from?** The installer could stamp an origin in the
  install log. A `git ls-remote` returns a SHA, not a count, so a remote SHA does not compare
  without fetching. A published version file is a network call.
- **Does it belong in `orient`?** That is where a person would see it, and `orient` is the
  thing everyone runs first. It is also capped at about 700 tokens, and it is the one command
  whose cost is the point.
- **Report or gate?** "Report, don't gate" is one of the eight values. An install five days
  stale is also the reason a fixed bug was reported twice and diagnosed twice.
- **What does a target do with the answer?** Telling someone they are behind is only useful
  with the command that fixes it, and that command is an install against their path — which
  the toolkit cannot know from inside their repository.
- **Does this generalise past staleness?** An install log that knows its own provenance could
  also answer "which version wrote this file", which is the question behind every report that
  begins "the toolkit does X" when the toolkit stopped doing X two releases ago.

## Related

Not the same as the sed matrix, which is still unfiled: 63 `sed` invocations across 12 shipped
files have only ever run under GNU sed, and the #0035 guard catches one shape of one bug. That
is a real gap and it is not this one. This draft is about a fix that existed and did not
arrive.
