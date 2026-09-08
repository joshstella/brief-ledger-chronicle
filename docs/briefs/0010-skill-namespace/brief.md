# The skills live in someone else's namespace

**Serial:** #0010 · **Created:** 2026-09-08T03:20:00Z · **Author:** josh.stella@gmail.com · **Depends on:** #0009

## Ground

This toolkit ships ten skills: `chronicle`, `commit-push-pr`, `create-brief`,
`init-briefs`, `installer-builder`, `next-brief-phase`, `review-pr`, `start-brief`,
`ste-writing`, `to-do`. None of them owns its name.

A skill name is not scoped to the repository that installed it. The host merges every
skill it can see into one flat list and asks a model to choose from it. `.cursor/skills/`
and `~/.cursor/skills-cursor/` are different directories, but by the time a name reaches
the agent, that distinction is gone.

Cursor currently ships twenty-four of its own: `automate`, `autopilot`, `canvas`,
`create-hook`, `create-rule`, `create-skill`, `create-subagent`, `goal`, `loop`,
`migrate-to-skills`, `new-repo`, `onboard`, `origin`, `rename-chat`, `review`,
`review-bugbot`, `review-security`, `sdk`, `share`, `shell`, `split-to-prs`,
`statusline`, `update-cli-config`, `update-cursor-settings`.

Nothing collides exactly today. That is the whole problem: it is a fact about this
week, held in place by nobody, and the toolkit is about to be handed to a team.

This brief is filed while the toolkit has exactly one user in anger, who is its author.
That is the cheapest this change will ever be, and the window closes on adoption.

## The claim

Nine skills are renamed `blc-<name>`, uniformly, with no exceptions for the ones that
read fine unprefixed. The tenth, `to-do`, is removed rather than renamed.

The prefix is not primarily a defence against collision. It is a discovery affordance:
typing `/blc-` completes into the entire workflow, which is the only way a newcomer
learns what BLC offers without being handed documentation. Collision-proofing is the
second benefit, not the first.

There is no migration path and no deprecation window. With one install to fix and its
owner doing the fixing, a compatibility mechanism would cost more to build, test, and
carry than the thing it spares. Reinstalling is the migration.

The record is not rewritten. Briefs and ledgers that name `start-brief` keep naming it.

## Evidence

**Three names are already ambiguous, without being duplicates.** `review-pr` sits beside
native `review`, `review-bugbot`, and `review-security`; a model asked to review something
now picks from four candidates with no strong signal. `to-do` overlaps native `goal` and
the host's built-in todo tooling. `commit-push-pr` neighbours `split-to-prs`.

**Six of the ten are typed by humans.** `install.sh` installs `commit-push-pr`,
`create-brief`, `init-briefs`, `next-brief-phase`, `review-pr`, and `start-brief` as
Claude Code slash-commands. That is a namespace a person types from memory, where a
near-miss costs more than a model's mis-selection: the person gets no ranked list and
no second guess.

**`to-do` is not a process skill.** It appends a timestamped line to `docs/to-dos/todo.md`.
It touches no brief, no ledger, and no chronicle, and it is named in `README.md` and two
test files but by no skill in the workflow. Prefixing it would assert that a generic note
logger is part of brief-ledger-chronicle, which is a claim this toolkit should not make
about a utility that ships beside its own host's equivalent.

**The generic names are the ones most likely to be taken.** `chronicle` and `review-pr`
describe jobs any host might ship. `installer-builder` and `ste-writing` are safe by
obscurity, which is not a property worth relying on.

**The host adds natives without asking.** `onboard`, `goal`, and `review` did not exist
in this list indefinitely. There is no mechanism by which a future addition consults an
installed project, and no warning when one lands on a name already in use.

**The blast radius outside the record is small and known.** Twenty-four files name a
skill, excluding `docs/briefs/`. The change is mechanical throughout.

## Change

Two phases. The rename is one atomic move — a half-renamed toolkit is broken on both
hosts, so there is no useful place to stop in the middle.

| Phase | Work |
|---|---|
| `a — the names` | Rename nine directories under `skills/` to `blc-<name>` and delete `skills/to-do/`. Update `PROCESS_SKILLS` in `install.sh`, the machine-mode symlink loop, and the template-presence check. Update every cross-reference in `README.md`, `Manifesto.md`, `docs/`, and the skills' own prose, including the `to-do` mentions in `README.md` and `docs/slides-process-overview.md`. Write the naming rule into `docs/briefs/README.md` so the next skill is born prefixed rather than renamed later. |
| `b — the check` | Tests that a fresh install places nine skills, all prefixed, and six slash-commands, all prefixed; that no unprefixed name and no `to-do` survives anywhere outside `docs/briefs/`; and that both hosts agree on the six. Update the `to-do` assertions in `tests/test_hosts.sh` and `tests/test_machine_mode.sh`, which currently require the skill this phase removes. |

## Tension

**Four characters, paid daily, forever.** `/blc-start-brief` is worse to type than
`/start-brief`, and no amount of namespace hygiene makes that keystroke back. The bet is
that tab-completion collects the cost once and that discovery repays it on every new
contributor — but the person paying today is the one user who already knows all nine
names and receives nothing for it until others arrive.

**Renaming the week before handoff is bad timing, twice over.** Doing it before the team
installs is far cheaper than after; that is the argument for now. But it also means any
tutorial, note, or screen recording made before the rename is stale on arrival.

**The record will name skills that no longer exist.** Briefs and ledgers back to #0001
say `start-brief`, and #0001's ledger names `to-do`. They are the hypothesis as entered
and do not get rewritten, so the repository will permanently contain correct history in
obsolete vocabulary. This is the same seam #0009 accepts for phase numbering, taken for
the same reason, and it is a real cost to a reader who does not know to expect it.

**No migration path is a decision that expires.** It is correct precisely once, while the
install count is one and the installer is the author. Every later rename in this toolkit
will have to build the thing this brief is skipping, and this brief should not be cited
as precedent for skipping it again.

**Removing `to-do` deletes a working tool to buy consistency.** It does its job. The
argument against it is categorical rather than functional — it does not belong to this
process — and anyone relying on `/to-do` loses it with no replacement beyond the host's
own equivalent.

**Uniform prefixing over-applies the rule on purpose.** `installer-builder` and
`ste-writing` collide with nothing and are unlikely to. Prefixing them anyway buys a rule
a person can state without exceptions; prefixing only the ambiguous names would mean every
contributor has to remember which ones got the treatment.

## Settled decisions

**All nine, not a subset.** A rule with exceptions is a rule nobody recalls correctly.

**`blc-`, hyphenated, lowercase.** It matches the existing skill-name shape and is a legal
directory name and slash-command on both hosts.

**`to-do` is removed, not renamed.** It is not part of this process and duplicates host
tooling. Kept locally by whoever wants it; not shipped by this toolkit.

**`ste-writing` is kept, as `blc-ste-writing`.** It fails the same surface test as `to-do`
— it touches no brief, ledger, or chronicle — and is kept anyway, so the distinction is
stated rather than left implied. A record is only useful if it can be read, and house voice
is what keeps briefs and ledgers legible to someone arriving cold. That makes it part of
the process by its effect on the record, where `to-do` acts on a file the process never
reads. The skills' own prose is written in that voice, so removing it would strand the
convention the rest of the toolkit follows.

**No migration, no aliases, no deprecation window.** One install, owned by the author.
Reinstalling is the migration, and a period where both names work is a period where the
ambiguity is worse.

**The installer does not delete.** It has never removed a file from a target and does not
learn to here. Stale unprefixed skills in an existing install are removed by hand.

**The record is not rewritten.** Filed briefs and ledgers keep the vocabulary they were
written in, per the same reasoning as #0009's forward-only seam.

## Open decisions

None. The one question this brief raised — whether `ste-writing` survives the test that
removes `to-do` — is settled above.

## Non-goals

**Not changing what any surviving skill does.** This is a rename, plus one removal.

**Not phase naming.** #0009 owns that.

**Not a Contract clause.** No promise about skill names is worth versioning yet.

**Not renaming skills in briefs, ledgers, or git history.**

**Not a general namespacing mechanism.** No registry, no manifest, no collision detector.
Nine known names, renamed once.

**Not building the migration this brief skips.** A later rename will need it; this one
does not.

## Success criteria

A fresh install into an empty project places nine skills, all `blc-`-prefixed, and six
slash-commands, all `blc-`-prefixed.

`rg 'start-brief|review-pr|to-do'` outside `docs/briefs/` returns nothing unprefixed and
no surviving `to-do`.

The full test suite passes with the `to-do` assertions in `tests/test_hosts.sh` and
`tests/test_machine_mode.sh` removed rather than adjusted to a renamed skill.

`docs/briefs/README.md` states the naming rule, so the next skill is born with the prefix.
