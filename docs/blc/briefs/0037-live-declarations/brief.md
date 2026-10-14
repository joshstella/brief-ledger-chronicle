# The declarations orient counts are files, not claims

**Serial:** #0037 · **Created:** 2026-10-14T00:33:39Z · **Author:** josh.stella@gmail.com · **Depends on:** —

`orient` lists every non-empty file in `docs/blc/state/` under **Picked up, not yet filed**,
whether or not that file claims anything. Reported from a downstream repository on
2026-10-13, where two contributors appeared as open claims on every run for weeks. Both
files said they had nothing unfiled.

## The defect

`tools/orient.sh:152` computes the claim lines and throws them away:

    sed -n 's/^## /  · /p' "$f"
    declared=$((declared + 1))

The `sed` is the liveness test. A declaration's entries are `##` headings, so a file with no
`##` heading makes no claim and prints no line. The counter on the next line increments
anyway, because it counts the file.

Everything downstream follows from that. Line 142 rejects only a zero-byte file — `[ -s "$f" ]`
— so a stub with prose survives. Line 151 prints the name and a date before any claim is read.
Line 156 prints "Nobody has declared unfiled work." only when the count is zero, which a
directory of stubs never reaches. Line 125 prints the heading unconditionally, above whatever
follows.

**The program already calculates the test it needs and does not look at it.** The fix is to
keep that output, skip the file when it is empty, and count only when it is not.

Liveness should come from structure, not from prose. Matching "nothing picked up and unfiled"
would be phrase-matching a file people write by hand, in whatever words they chose that day.
A `##` heading is the entry shape the directory already uses.

## Why it is expensive

`orient` is the cheap read, and this section is the one thing in it that no ledger can
supply — work somebody picked up before a serial exists. A false positive there is not noise
in a long report. It is noise in the only channel that warns about the serial race, and age
does not separate the two: the stubs in the report were already old, and a real claim is new
and therefore looks the same as the oldest stub next to it.

## The cause is a sentence that stops too early

`docs/blc/state/README.md` is already right. Line 70: "Clearing an entry is deleting it — an
empty file, or no file at all, is the correct steady state for someone with nothing unfiled."
Line 51: "A declaration nobody has cleared is a bug, not a history."

The skills that clear a declaration do not say that last part.
`blc-create-brief:73` says "delete that entry". `blc-close-brief:92` says "remove the entry".
Neither says what to do when that entry was the only one. An agent that follows either
literally removes the `##` block and leaves the header and the surrounding prose, which is a
non-empty file that claims nothing — the exact input the defect above mishandles.

The skills do not contradict the README. They stop one sentence short of it.

## Nothing has ever tested the case

`tests/test_orient.sh:47` builds every state fixture the same way:

    printf '# %s\n\n## 2026-09-09 — %s\n' "$1" "$2"

Always a `##` entry. Always live. **No fixture anywhere feeds `orient` a state file that
claims nothing**, which is why a defect this visible survived in the output everybody reads
first. A guard that has never met the case it exists for is unproven, and here there was no
guard at all.

## Claim

Count claims rather than files. Say in both skills that removing the last entry means
deleting the file. Cover the non-live case with a fixture, so the regression has somewhere to
fail.

## Out of scope

- **The serial race.** `docs/blc/state/` is the claim channel and Contract v1.5 already
  records that reading the remote narrows the window without closing it. This brief makes
  that channel quiet. It does not change what it guarantees.
- **Pruning the directory.** Nothing removes an abandoned declaration today, and the
  comment at line 144 says age is reported rather than enforced on purpose. A live claim
  that nobody cleared is still a live claim, and deciding when it stops being one is a
  different argument.

## Open

- **Does a `##` heading that says "nothing unfiled" count as a claim?** Structure says yes,
  intent says no. The reported stubs used prose, so the observed case is covered either way,
  and the README's rule is to delete the file rather than describe its emptiness.
- **Should the heading itself be conditional?** Printing **Picked up, not yet filed** above
  "Nobody has declared unfiled work." is a heading that is true of nothing. Harmless, or the
  same defect one level up.
- **Should anything fail on a stub**, so the drift cannot return? A `brief-checks/` script
  could, but the directory is project-owned per-contributor state and a gate that fails on
  someone else's file is a gate one person cannot clear.
