# Jira as a reporting surface, written from BLC

**Serial:** #0007 · **Created:** 2026-09-07T16:36:27Z · **Author:** josh.stella@gmail.com · **Depends on:** —

## Ground

The convention already named a tracker field. `docs/briefs/README.md` says a Jira key is
a correlation ID on the identity line (`· **Jira:** PROJ-1234`), "added when wired."
`create-brief` says it will carry that field if the draft had one. The Manifesto says a
tracker is optional, never load-bearing, and must not be required to exist.

#0005 already split **Author** (who filed) from **owner** (who runs `start-brief`). It
refused to collapse them into one field. It also refused an assignee field as a work
queue. The owner is still only a README sentence. Nothing on the identity line names
them. `open-briefs.sh` lists what is open. It does not fetch, and it does not filter by
who owns the serial.

PMs need a reporting surface they already know. That surface is Jira. Executors need to
pull `main` and ask what is theirs. Humans change work through BLC. Jira is published
from that. Assignments are read from git.

## The claim

**Jira is a one-way reporting surface for BLC. Ownership is an email on the brief.**

A brief generates an Epic. Each phase generates a ticket under that Epic. When a human
updates a brief or ledger through BLC, the connector creates those artifacts if they are
missing and sets their status to match the ledger. The Epic assignee is the brief
`Owner`. PMs read Jira. They do not write the record there.

Jira never files a brief, never edits a ledger, and never wins a conflict. A ticket a PM
transitions by hand is stale reporting until the next BLC write. The next write puts it
back.

An executor fetches, then asks what they own, and gets a list from the briefs on disk.
That list is not a pile to take from. It is what was already assigned to their email.

A project with no Jira is unchanged. Missing config is ordinary, not an error. The
process does not wait on Jira. `Owner` still works with no Jira: the assignments skill
does not need a ticket to answer.

## Evidence

All of this is in this repository. Nothing here is supplied from a Jira tenant.

**1. The Jira field is named and not built.** README "Correlation IDs": the serial stays
internal; a tracker key is a separate field; "added when wired." `create-brief` mentions
`Jira:` as a future carry. `grep` of `tests/` finds no `Jira`. Contract v1.1 has no
clause for it.

**2. Owner is named and not a field.** README: "`Author` on the identity line is who
filed. The owner is who executes. Those can be different people. They are not two
fields to merge." #0005: "This brief does not build a work queue … or an assignee
field." The distinction exists. The field does not. Assignment today is memory and chat.

**3. `open-briefs.sh` is the wrong shape for "what is mine."** It reports every open
serial. It does not fetch: a reporting command that mutates git would be a surprise.
Distances are only as fresh as the last fetch. An executor who forgot to pull gets a
stale list. The new skill must fetch first. The query program must not.

**4. The Manifesto forbade a load-bearing integration, not a report.** One-way publish
still has to keep that bar: BLC runs without Jira.

**5. Auth and network are not in this toolkit.** `install.sh` does not check a Jira
host or a token. Secrets must not land in `docs/briefs/`.

## Change

Five phases. Mapping and fields first. Publisher and assignments query are independent
once `Owner` and the Jira keys exist. Tests land with the program they pin.

| Phase | Work |
|---|---|
| 1 — the mapping | README: Jira is optional reporting. Brief → Epic. Phase → ticket. `Owner:` is an optional email on the identity line, distinct from `Author`. Keys live on the brief and the ledger, not in the serial. Drop "added when wired." Amend the Manifesto so "not load-bearing" still holds and one-way publish is named. Not a Contract clause. |
| 2 — store the fields | `create-brief` carries `Owner:` and the Epic key. `start-brief` / `next-brief-phase` grow a place for per-phase ticket keys. Present keys and emails are shape-checked. Absence of Jira or Owner is fine. No Jira call. |
| 3 — the publisher | A program that, when Jira is configured, creates the Epic and the phase tickets, sets Epic assignee from `Owner`, and transitions from `blc/1`. When Jira is not configured, it exits zero and writes nothing. It never reads Jira to update a brief or ledger. |
| 4 — my assignments | A program that lists open briefs for an email (`Owner`, or `Author` if `Owner` is omitted). It does not fetch. A skill fetches (or `pull --ff-only`), then runs the program, then shows the list. Default email is `git config user.email`. Not a work queue: it does not offer unowned pending briefs. |
| 5 — the check | Tests for: no Jira config → no-op; create Epic and tickets; assignee from `Owner`; transition; Jira-side edit overwritten; malformed key or email rejected; assignments filter; omitted `Owner` counts as `Author`; query does not fetch; secrets not in git. |

Phase 2 precedes 3 and 4. 3 and 4 can land as two PRs. Skills call the programs. They
do not speak HTTP. The assignments skill's fetch is an instruction. The query is a
program so the filter is checkable.

## Tension

Publishing Epics *looks* like making Jira the board. Writes only flow out. A PM who
closes a ticket in Jira has not closed the phase. The next BLC run restores Jira. That
will feel like a bug to anyone who treats Jira as the record.

#0005 refused an assignee field so this toolkit would not become a pickup queue.
`Owner:` is that field, used as correlation: Jira assignee, and "what is mine after
fetch." It is not a board of unowned work. `open-briefs.sh` stays the all-open report.
If the assignments skill ever lists briefs with no owner as takeable, this brief has
failed.

The Manifesto said carry an ID, not "create issues." This brief extends that sentence.
If create-or-transition failure can block filing, Jira has become load-bearing. This
brief forbids that (open decision 3).

## Settled decisions

Resolved 2026-09-07 in this revision.

- **One-way, BLC → Jira.** Humans update via BLC. The connector creates artifacts and
  changes their status. Jira is not imported. Two-way sync is out.
- **Brief → Epic. Phase → ticket.** One Epic per brief. One ticket per phase, child of
  that Epic.
- **PMs report from Jira.** They are not the writers of status.
- **Optional Jira.** No config, no artifacts, BLC unchanged.
- **`Owner:` is a separate identity-line field.** Email-shaped. Not `Author`. #0005's
  split stands. This is correlation, not a work queue.
- **Omitted `Owner` means `Author`.** Solo filing does not need a second field to show
  up in "my assignments" or as the Epic assignee.
- **Assignments skill fetches, then lists.** The query program does not fetch, same
  rule as `open-briefs.sh`. Default identity is `git config user.email`.
- **The record stays in git.**

## Open decisions

These block the phase named.

1. **When is the Epic created?** Default: Epic at filing, tickets at `start-brief`,
   transitions whenever `blc/1` changes. Blocks phase 3.
2. **Where do phase ticket keys live?** Identity line holds Epic and Owner. Phase keys
   need a field per phase. `blc/1` is already dense. Blocks phase 2.
3. **Jira is down.** Confirm: warn, do not block. Blocks phase 3.
4. **Status map.** Default: a small config map, not hardcoded "In Progress". Blocks
   phase 3.
5. **Where auth lives.** Env, a gitignored project file, or a CLI. No tokens in git.
   Blocks phase 3.
6. **Contract clause?** Default: no new Contract version. Validate shape if `Jira:` or
   `Owner:` is present. Blocks phase 2.
7. **Extend `open-briefs.sh` or a sibling?** Same scan, extra filter. A flag is less
   surface. A sibling keeps "all open" and "mine" from growing one script. Blocks
   phase 4. Default: flag or filter on `open-briefs.sh`, skill is the fetch wrapper.
8. **Which states are "assigned"?** `pending`, `in-progress`, and `deferred` are work
   someone still owns. `done` and `skipped` are not. Confirm. Blocks phase 4.

## Non-goals

- **Not two-way sync.** A Jira webhook does not edit a ledger.
- **Not import.** A ticket does not become a brief.
- **Not a pickup queue.** Unowned pending briefs are not offered as takeable.
- **Not a Jira replacement.** Sprint boards and estimation stay in Jira if the team
  uses them.
- **Not creating tickets for work that is not a phase.**
- **Not secrets in git.**
- **Not a Contract clause** in this draft (open decision 6).

## Success criteria

- Filing a brief in a configured project yields an Epic key and, if Jira is on, an
  Epic assigned to `Owner` (or `Author` when `Owner` is omitted).
- Starting a brief yields one ticket per phase, under that Epic.
- A ledger status change updates the matching Jira statuses. A hand edit in Jira
  does not update the ledger. The next BLC write restores the Jira side.
- `Owner:` on the identity line is optional, email-shaped, and distinct from `Author`.
- After fetch, an executor can ask what they own and get only their open serials.
- A project with no Jira config files, starts, validates, and lists assignments.
- The suite pins create, transition, no-op, overwrite-of-Jira-side-edits, and the
  owner filter.
- The Manifesto still says the tracker is not load-bearing.
- The assignments path does not list unowned work as a queue.
