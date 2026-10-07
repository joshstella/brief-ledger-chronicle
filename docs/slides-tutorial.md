# brief-ledger-chronicle — Tutorial

*How to use it. What each command does. How a brief moves through branches.*
*18 slides. Suggested layout: dark background, monospace for commands and branch names.*

> **Names.** This deck uses the skill name, `blc-create-brief`. On Claude Code you may
> also type `/blc-create-brief`. On Cursor you invoke the skill by name. The steps are
> the same.
>
> **Skills and checks.** A skill is an instruction to an agent. Nothing runs it for you.
> A tool under `tools/` is a program. The test suite can fail a tool. It cannot fail a
> skipped skill. Where a slide says a skill does something, that is the instruction.

---

## Slide 1 — Cover

**How to use brief-ledger-chronicle**

One brief. A ledger of what the work taught. A branch per phase. One path onto `main`.

---

## Slide 2 — Three files, then git

| File | Role | Path |
|---|---|---|
| Brief | The claim you start with | `docs/blc/briefs/NNNN-slug/brief.md` |
| Ledger | What execution cost, including where the brief was wrong | `docs/blc/briefs/NNNN-slug/ledger.md` |
| Chronicle | A story rendered from those two and from git | `docs/blc/chronicles/chronicle.md` |

The brief and the ledger are the record. The chronicle is a rendering. A later run may refresh it.

Git holds the branches, the pull requests, and the commits on `main`.

---

## Slide 3 — Skills and tools

**A skill tells an agent what to do. A tool is a script.**

Process skills, in the order you meet them:

| Skill | When you use it |
|---|---|
| `blc-init-briefs` | Once, if `docs/blc/briefs/` is missing |
| `blc-orient` | Before you trust a picture of the repo |
| `blc-create-brief` | When a draft becomes work |
| `blc-start-brief` | When you are ready to execute |
| `blc-commit-push-pr` | When a phase is ready for review |
| `blc-review-pr` | The gate inside that command, or a review you ask for |
| `blc-next-brief-phase` | After a phase has merged and another remains |

Also: `blc-my-briefs`, `blc-chronicle`, `blc-prune-stale-branches`, `blc-ste-writing`, `blc-installer-builder`.

Tools you will see named: `tools/orient.sh`, `tools/open-briefs.sh`, `tools/validate-briefs.sh`, `tools/stale-branches.sh`.

---

## Slide 4 — The path of one brief

```
_drafts/idea.md                         no serial, no branch
        │  blc-create-brief
        ▼
NNNN-slug/brief.md                      serial assigned, still no branch
        │  blc-start-brief
        ▼
ledger.md pushed to main                the only ledger push straight to main
        │
        ▼
brief/NNNN-a-<kebab>                    phase a
        │  blc-commit-push-pr → PR → squash onto main
        ▼
brief/NNNN-b-<kebab>                    marks a done, does phase b
        │  same path
        ▼
brief/NNNN-closeout                     marks the last phase done
        │  PR → squash onto main
        ▼
main holds the closed ledger
```

Each box is a later slide.

---

## Slide 5 — Read the repo before you edit it

**Command:** `blc-orient`

It runs `tools/orient.sh`. About 700 tokens.

It reports:

- Which briefs are open, and their status.
- Work someone picked up and has not filed.
- What an install wrote, and what the project values.
- Whether this checkout is behind its upstream.

If the freshness line says you are behind, fetch and run it again. The rest of the output describes a tree that has already moved.

`blc-orient` writes nothing.

`blc-my-briefs` answers a narrower question. It fetches, then lists open briefs whose Owner is you, or whose Author is you when Owner is absent.

---

## Slide 6 — A draft is not a branch

You write the draft yourself. No skill assigns it a number.

```
docs/blc/briefs/_drafts/invoice-totals.md
```

The file has a title and a provenance line: `Created` and `Author`. It has no serial.

Commit the draft when you want it on another machine. Filing is the decision to do the work. A draft can wait. It leaves no gap in the serial sequence.

`blc-init-briefs` creates `_drafts/` and the briefs README when they are missing. The installer usually creates them first. The command does not commit.

---

## Slide 7 — Say you are taking a number

Two checkouts can both see the same next serial. Both are right until one push lands.

Before you file, write your claim in your own file:

```
docs/blc/state/<your git email, lowercased>.md
```

One file per person. You write yours and no one else's.

`blc-orient` is how someone else sees the claim. `blc-create-brief` warns if another person's file already claims that serial.

When the brief is filed, delete the claim. A declaration that repeats the record goes stale.

---

## Slide 8 — `blc-create-brief`

**When:** the draft is the work you have decided to do.

```
blc-create-brief docs/blc/briefs/_drafts/invoice-totals.md
```

What it does:

1. Stops if `docs/blc/briefs/` or `_drafts/` is missing. It tells you to run `blc-init-briefs`.
2. Takes the next serial. That is max plus one, among folders whose names start with four digits.
3. Writes `docs/blc/briefs/0042-invoice-totals/brief.md`.
4. Puts one identity line under the title. Serial, Created, Author, Depends on. Owner and Jira only if the draft had them.
5. Removes the draft file.
6. Clears your serial claim in `docs/blc/state/`, if you wrote one.

What it leaves alone:

- The git index. The new brief stays uncommitted.
- Branches. None is created.
- The ledger. Execution writes that.

The brief reaches `main` with the ledger push on the next slide, or by its own pull request before start. The skills do not name a filing branch.

The serial encodes identity only. One brief per run.

---

## Slide 9 — `blc-start-brief`

**When:** the brief is filed and you are the person who will execute it.

```
blc-start-brief 0042
```

What it does:

1. Stops if `ledger.md` already exists. It does not overwrite that file unless you confirm a restart.
2. Runs `blc-orient`, then reads the brief and the code it will touch.
3. Plans the phases. Each phase gets a letter and a short label. Example: `a — the parser`.
4. Writes `ledger.md` beside the brief. Status starts as `pending`.
5. Commits that ledger and pushes it to `main`.
6. Asks before it cuts the first branch: `brief/0042-a-the-parser`.

Step 5 is the exception. It is the only ledger write that goes straight to `main`. Every later ledger edit is committed on a branch and reaches `main` by merge.

The push happens before the phase branch exists. The plan is then on every machine that pulls. The first phase squash cannot drop it.

One person owns the serial. Phases are that person's sequence.

---

## Slide 10 — How a branch is named

A phase id is a letter. Every other name comes from that letter.

| | Form | Example |
|---|---|---|
| Phase id | `<letter> — <label>` | `b — the report` |
| In prose | `#<serial>/<letter>` | `#0042/b` |
| Branch | `brief/<serial>-<letter>-<kebab>` | `brief/0042-b-the-report` |
| Pull request title | `[#<serial>] <summary>` | `[#0042] Add the report` |

Rules that keep git usable:

- The branch has one slash. It belongs to `brief/`.
- A second slash makes two refs that git cannot hold at once.
- Serials stay zero-padded in anything written down. `42/b` is speech only.
- The prefix is `brief/`, because a brief is an assignment. It may be smaller than a feature or larger.
- Twenty-six phases is the ceiling. A 27th phase is a new brief.

`brief/0042-closeout` is reserved. It is not a phase. Slide 15 uses it.

---

## Slide 11 — Work, then `blc-commit-push-pr`

You do the phase on its branch. Code and later ledger edits both live there.

When the phase is ready:

```
blc-commit-push-pr
```

The command refuses to run on `main` or `master`. A pull request cannot open from the default branch.

What it does, in order:

1. Asks `tools/detect-forge.sh` which forge is logged in. GitHub uses `gh`. GitLab uses `glab`. A GitLab request is a merge request, written `!123`.
2. Stages the files you name. It leaves out secrets and build output.
3. Runs `blc-review-pr --staged` on that diff. It waits.
4. On **Request changes**, it stops. Nothing is committed. Nothing is pushed. The files stay staged.
5. On **Approve**, it commits, pushes, and opens the pull request.
6. The title starts with `[#0042]` when the work executes that brief. Squash merge copies the title onto `main`.

The pull request body carries `## Summary`, `## Test plan`, and `## Brief`. The Brief line names the serial, the brief path, and the phase. That is how a later review finds the claim.

When the pull request exists, write its number into the phase pointer on this same branch. Example: `in-progress(brief/0042-a-the-parser,PR#14)`. Separate pointer fields with commas. Use no spaces.

---

## Slide 12 — What the review is allowed to stop

**Command:** `blc-review-pr`

`blc-commit-push-pr` calls it before the commit. You can also call it on a pull request number, or on the current branch.

A **Request changes** verdict blocks the commit. **Approve with suggestions** lets the commit proceed. You still receive the suggestions.

The review checks a mechanical floor:

- Correctness.
- Tests that cover the change, and that you ran.
- Whether the diff stays inside the phase.
- Types, scope, security, and comments.

A missing test blocks, unless the test plan says `test-exempt because…` and the reason is real.

Architecture stays your call. The review separates three labels: `Verified`, `Couldn't verify`, and `Your call`.

---

## Slide 13 — Merge does not close the phase

You squash-merge the pull request. `main` receives one commit. Its subject is the pull request title. `[#0042]` stays in history.

After that merge:

- The forge usually deletes the phase branch.
- `main` has the code.
- The ledger on `main` still says the phase is `in-progress`.

Leave the `done` line off `main`. The finished branch is already merged. It is no longer a path back.

The next branch carries the closing line. That line reaches `main` when the next branch merges.

---

## Slide 14 — `blc-next-brief-phase`

**When:** the previous phase pull request has merged, and the brief is still `in-progress`.

```
blc-next-brief-phase 0042
```

What it does:

1. Reads the ledger and the brief.
2. Checks that the previous pull request merged. If the forge command fails, it stops.
3. Re-plans the phases that remain. A finding in phase a can reorder, split, or drop a later phase.
4. Runs `blc-orient` again. The tree has moved.
5. Asks, then cuts the next branch from current `main`: `brief/0042-b-the-report`.
6. On that branch, marks phase a `done` with its pull request. Sets phase b to `in-progress` and records the new branch in the status field.
7. Commits that ledger on the new branch. It does not push it to `main`.

If phase a and phase b do not depend on each other, the plan says so. Those branches can exist at the same time. They are still one owner's sequence.

A parked phase is `deferred`. The status names the branch. The reason goes in the phase table. Deferral does not keep the branch from going stale.

---

## Slide 15 — The closeout branch

The last phase has no next letter. Nothing is left to carry its `done` line.

After that pull request merges, cut:

```
brief/0042-closeout
```

On that branch, mark the last phase `done` and mark the brief `done`. Send the branch through `blc-commit-push-pr`.

When that pull request squashes, `main` shows the brief as done.

`blc-next-brief-phase` is for the next letter. Closeout is the branch that remains when no letter remains.

---

## Slide 16 — Five status words

The brief and each phase use the same five words.

| State | Meaning | Pointer |
|---|---|---|
| `pending` | It has a place. Work has not started. | none |
| `in-progress` | A branch exists. | the branch, and the pull request once it exists |
| `deferred` | Parked on purpose, with a reason. | the branch, as above |
| `done` | Finished. | the pull request, or a commit if there is no forge |
| `skipped` | Will not be done. | a reason, no branch |

`done` points at a pull request. The branch is usually gone.

The ledger repeats this in one line under the title:

```
`blc/2 #0042 in-progress a:done(PR#14) b:in-progress(brief/0042-b-the-report)`
```

Update that line in the same edit as the table. A stale line is worse than no line. A cheap reader trusts it and stops.

Write `blc/2` in a new ledger. Older briefs may still say `blc/1` and number their phases. Leave those lines as they are.

---

## Slide 17 — Commands that read, and one that deletes

| Command | What you get | What it changes |
|---|---|---|
| `blc-orient` | Open work, claims, values, freshness | nothing |
| `blc-my-briefs` | Open briefs assigned to an email | fetch, and a fast-forward if you are on the default branch |
| `tools/open-briefs.sh` | Each `in-progress` and `deferred` phase, and how far `main` has moved | nothing |
| `tools/validate-briefs.sh` | Contract defects, then `brief-checks/` | nothing |
| `blc-chronicle` | `docs/blc/chronicles/chronicle.md` | that file |
| `blc-ste-writing` | Prose in the house style | the text you asked it to rewrite |
| `blc-prune-stale-branches` | Local branches whose work the trunk already has | deletes only the ones you confirm |

`open-briefs.sh` reports. A merge does not wait on it. Run it when you want to see a phase that has been parked.

Prune fetches, then runs `tools/stale-branches.sh`. It shows what it proved. It asks. It deletes only branches you name, and only if the proof still holds. It does not offer a branch it could not prove.

---

## Slide 18 — One brief, end to end

Brief `#0042`, two phases. `a — the parser`, then `b — the report`.

| Step | Where you are | Command | Git after this step |
|---|---|---|---|
| 1 | `main` | write `_drafts/invoice-totals.md` | a draft, if you commit it |
| 2 | `main` | write your state file | a claim `orient` can show |
| 3 | `main` | `blc-create-brief` | `0042-invoice-totals/brief.md` in the work tree |
| 4 | `main` | `blc-start-brief` | ledger pushed to `main`, then `brief/0042-a-the-parser` |
| 5 | phase a | do the work | commits on that branch only |
| 6 | phase a | `blc-commit-push-pr` | review, then a pull request |
| 7 | `main`, after the squash | `blc-next-brief-phase` | `brief/0042-b-the-report` marks a `done` |
| 8 | phase b | work, then `blc-commit-push-pr` | second pull request |
| 9 | `main`, after the squash | cut `brief/0042-closeout` | that branch marks b and the brief `done` |
| 10 | closeout | `blc-commit-push-pr` | squash puts the closed ledger on `main` |

Keep the path intact:

- Send phase work through `blc-commit-push-pr`.
- Let `blc-create-brief` assign every serial.
- After step 4, edit the ledger on a branch. It reaches `main` by merge.
- Leave an installed skill unchanged. The next install replaces it.

---

*End of deck.*
