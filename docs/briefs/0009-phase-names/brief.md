# One name for a phase, used everywhere

**Serial:** #0009 · **Created:** 2026-09-07T17:00:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0004

## Ground

A phase already has a stable id in the ledger (`phase 1 — the digest`). `blc/1` numbers
it (`1:`). `start-brief` and `next-brief-phase` tell the agent to branch from that id.
`commit-push-pr` cites it. `review-pr` scopes a diff to it. #0007 will turn each phase
into a Jira ticket a PM reads.

Talking to an agent, **numbers already mean serials** (`#0006`, `#0007`). Phases also
use numbers (`phase 3`). "Do 3 on 6" is ambiguous. Letters for phases would let speech
and chat split the two: numbers are briefs, letters are phases. `#0007/b` is one handle.

None of the surfaces share a written rule for the *words*. The skills say
`feature/<kebab>-<phaseN>`. This repo uses `brief/0006-the-digest`,
`brief/0004-phase-1-limitation-entry`, `brief/0006-manifesto`. Labels mix noun phrases
and verb phrases. Closeout is not a phase and still got `brief/0006-closeout`.

#0007 will copy the id onto a board. Settle it before that publisher exists.

## The claim

**A phase has one id. The index is a letter. Every other name is derived from it.**

Serials stay numbers (`#0007`). Phases are `a`–`z` in order. The id is
`<letter> — <label>`. The label is a short noun phrase, lowercase, two to five words.
Example: `c — the publisher`.

The separator is a slash: `#0007/b`. Spoken, "seven b". Not "phase 3 of 0007".
Serials stay zero-padded in anything written down. `7/b` is speech and chat only.

The status line uses the same letter: `blc/2 #NNNN in-progress a:done b:pending`. A
second numeric index beside the letter is how the names drift. New lines write `blc/2`
and letters; every reader still accepts `blc/1` with `1:` rows, which are never
rewritten.

The git branch keeps a hyphen, not the slash:
`brief/<serial>-<letter>-<label-as-kebab>`, e.g. `brief/0007-b-the-publisher`. The one
slash in a branch name stays the `brief/` ref namespace. A second one would make
`brief/0007` and `brief/0007/b` mutually exclusive refs.

The PR title still leads with `[#NNNN]`. The Jira summary is `#0007/b — the publisher`.

Reserved, not a phase: `brief/<serial>-closeout`.

Ceiling: 26 phases. This repository has not gone past five. A 27th phase is a new
brief, not `aa`.

Skills that still say `feature/<kebab>` and `phaseN` are updated. Old branches and old
ledger rows are not renamed.

## Evidence

**1. Number collision is already in the mouth.** `#0001` and `phase 1` share a digit.
`open-briefs.sh` prints both. An executor saying "start 1" is unparseable. Letters
remove that without making serials longer.

**2. The skills disagree with the repo.** `start-brief` / `next-brief-phase`:
`feature/<kebab>-<phaseN>`. Ledgers here use `brief/<serial>-…`. `open-briefs.sh`
resolves the stored string. It does not care. Humans and #0007 will.

**3. The status line already has an index, and the readers already expect it to move.**
`gather.sh` strips status with `[0-9]+:`; `open-briefs.sh` takes the token before `:`.
More usefully, `open-briefs.sh` matches the tag as `blc/*` and reports `no blc/N status
line` — #0004 wrote it version-agnostic. The alphabet change is a parser change in
`gather.sh` only, which hardcodes `blc/1` in two places.

**4. Labels are not a type.** #0005 used a verb phrase. #0006 used a proper noun.
#0007 already says `1 — the mapping`. Without a rule, Jira inherits the scatter.

**5. The separator was tested, not preferred.** Four candidates, checked 2026-09-07
against `git check-ref-format`, a shell, and this repo's own code.

| candidate | git ref | shell | this repo |
|---|---|---|---|
| `:` | rejected | — | already means index-to-status inside `blc/1` |
| `\|` | accepted | needs quoting | `gather.sh:19` rewrites it to `/` for markdown cells |
| `>` | accepted | **silently redirects** | — |
| `/` | accepted | inert | what `gather.sh` converts a pipe into |

`>` is the worst because nothing catches it: `git branch --list 0007>b-the-publisher`
created a file named `b-the-publisher`, dropped the argument, and exited zero. Colon
fails loudly. Pipe fails visibly. The slash is the only one that fails nowhere.

**6. The padding has exactly one job.** `ls`, glob expansion, and git's tree listing
sort as strings, so unpadded serials misorder at ten: `10-jira 2-multi-user
7-phase-names`. Padded, they don't. Nothing else depends on the zeros — serials are
allocated by numeric max-plus-one, `gather.sh` sorts the table by commit time, and
`#[0-9]+` would extract dependencies as well as `#[0-9]{4}` does. Four digits caps the
repository at 9999 briefs.

## Change

Three phases, split so the convention can land before the parsers move. Prose and
skills first, then the two readers, then the tests. No new Contract clause and no new
Contract version — v1.1 gets one over-specific phrase corrected in phase `a`.

| Phase | Work |
|---|---|
| `a — the convention` | Write the id shape (letter + label), the branch derivation, the closeout suffix, the Jira summary shape, and the 26-phase ceiling into `docs/briefs/README.md`. Point `start-brief` and `next-brief-phase` at it; they write `blc/2` and letter indexes. Record the seam where a reader meets it: phases before this brief are numeric, and why they stay that way. Reword Contract v1.1's collision-recovery step from "ledger `blc/1` line" to "ledger status line" — it must stop naming a version before any ledger writes `blc/2`. Prose and skills only; no parser and no clause touched. |
| `b — the readers` | Make both parsers dual-read. `gather.sh` hardcodes the version twice (the `grep -m1 'blc/1'` and the `^blc\/1` anchor in the status sed); both take `blc/[0-9]+`. `open-briefs.sh` already matches `blc/*`, but its drift check finds the phase-table row by `grep "^\|.*phase $idx "`, which matches neither a letter index nor a row written as `` `a — the convention` ``. Left alone it fails silent — reporting no drift rather than erroring — which is worse than breaking. |
| `c — the check` | Tests that both parsers read `blc/1` with numeric indexes and `blc/2` with letters, and that the drift check still fires on a letter-indexed ledger whose phase table disagrees. That last one is the regression that `b` would otherwise ship silently. |

## Tension

Letters are less ordinal for some readers than `1, 2, 3`. Order is still alphabetic,
and the table is still top to bottom. The win is speech: `#0007` is never `c`.

Forward-only leaves this repository visibly inconsistent: numeric phases through
#0007, letters after. That is accepted deliberately — see the settled decision — but
it is a real cost every reader pays, not a technicality. The bet is that a documented
seam teaches more than a uniform surface.

`blc/2` for a one-character alphabet change is a heavy-looking event. It is taken
anyway: a version tag heading two incompatible index alphabets is precisely what a
version exists to prevent, and #0004 wrote the readers to expect `blc/N` rather than
`blc/1`, which is a bet already placed.

Forcing `brief/` in a portable skill is this toolkit choosing for its install
targets. That is intended.

## Settled decisions

Resolved 2026-09-07 during drafting.

- **Letters for phases, numbers for briefs.** The split exists so speech and chat are
  unambiguous. `#0007` is never `b`.
- **The separator is a slash.** Colon, pipe, and `>` were each tested and each failed
  somewhere. See evidence 5.
- **Serials stay padded in every written form.** `#0007/b` in briefs, ledgers, PR
  titles, and Jira summaries. `7/b` is speech and chat only, normalized on the way in.
  The padding only *does work* in the folder name, where lexical order has to equal
  numeric order. It is carried everywhere else so there is one written form to teach
  rather than a rule about which contexts sort.
- **The branch keeps a hyphen.** One slash per branch name, and it belongs to `brief/`.
- **The prefix is `brief/`, not `feature/`.** A brief is an assignment, not a feature.
  It can be smaller than a feature (one clause, one script) or larger (a contract
  version, a workflow reversal). `feature/` would misdescribe most of what this
  repository has actually filed.
- **The status line becomes `blc/2`.** New ledgers write `blc/2 #NNNN in-progress
  a:done b:pending`. Old `blc/1` lines are never rewritten and must still parse, so
  every reader dual-reads. The version bump is what keeps one tag from heading two
  index alphabets — a reader written to the `blc/1` spec assuming numeric indexes
  genuinely breaks on `a:done`, and that is the break a version tag exists to
  announce. #0004 already wrote `open-briefs.sh` to match `blc/*` and to say `blc/N`
  in its own findings, so the readers were built expecting this.
- **Contract v1.1 is reworded in place, not superseded.** Its collision-recovery step
  reads "ledger `blc/1` line"; it becomes "ledger status line". No clause changes —
  BRIEFS-1 through BRIEFS-8 are untouched, and nothing parses a Contract, so there is
  no compatibility surface. The supersede precedent from #0005 covered a corrected
  *guarantee* about validator coverage. This is an over-specific phrase: the recovery
  step meant the status line regardless of schema version, so naming a version was
  always wrong. Weighed against: `install.sh` ships every Contract version to every
  target permanently, and a v1.2 whose whole delta is one word is downstream noise.
- **Forward-only. Nothing historical is renamed.** #0001–#0007 keep numeric phase
  indexes. Considered and rejected: a retcon of all ~180 numeric references, on the
  grounds that this repository doubles as a teaching example and ought to look
  consistent. Three arguments against, in order of weight.

  First, #0004 already bought the property that makes a retcon unnecessary. Its
  ledger: *"A fixed-position line makes the three inconsistent table schemas
  irrelevant to any scanner, with no migration. The schemas stay inconsistent and
  stop mattering."* Historical inconsistency is already costless to every reader.

  Second, a retcon cannot reach the git record. Merged branch names
  (`brief/0005-phase-1-state-assumptions`) and squash subjects (`[#0005] Mark phases
  1–3 done`) are on `main`. `gather.sh` reads commit subjects into the digest, so a
  generated `chronicle.md` would narrate "phase 3" beside a ledger saying `c`. The
  retcon trades a dated, explicable seam for one that reads as a defect.

  Third, the seam is the teaching material. A reader who sees numbers through #0007,
  letters from this brief onward, and a dual-read parser that exists *because* of that, learns
  how this workflow absorbs a convention change against live history. A repository
  retconned into looking always-consistent teaches that conventions arrive free.

## Open decisions

1. **Jira summary.** This draft takes `#0007/b — the publisher`. Binds #0007, does not
   block any phase here.

## Non-goals

- **Not renaming merged branches or old ledger ids.**
- **Not a Contract clause, and not a Contract version.** BRIEFS-1 through BRIEFS-8 are
  untouched. v1.1 gets one phrase corrected and stays current.
- **Not the Jira publisher.** That is #0007.
- **Not more than 26 phases.**

## Success criteria

- README states letter indexes, the branch, the closeout suffix, the Jira shape, and
  the ceiling.
- `start-brief` and `next-brief-phase` name branches that way.
- `open-briefs.sh` and `gather.sh` read `blc/1` with numeric indexes and `blc/2` with
  letters. New ledgers write `blc/2` and letters.
- `open-briefs.sh` still reports drift on a letter-indexed ledger. It does not go quiet.
- No Contract text names a schema version. `tests/test_contract_ship.sh` still passes
  and no new version file ships.
- In chat, `7/b` and `#0007/b` both mean phase `b` of serial 0007.
- No written artifact carries an unpadded serial.
- #0007 can cite this without inventing a second scheme.
- No historical ledger is rewritten, and no merged branch is renamed.
- `docs/briefs/README.md` explains the numeric-to-letter seam, so a reader hitting
  `1:done` in #0004 and `a:done` in any brief filed after it finds the reason rather than a defect.
