# Personal working agreement — global

Goes at `~/.claude/CLAUDE.md`, linked there by `install.sh --machine`. Applies to
every project on the machine. Project-specific facts — stack, directory layout,
build/test commands — live in each repo's own `CLAUDE.md`, not here. Keep this file
short; concise instructions are followed more reliably than long ones.

Adopt it as written or edit it to taste — it is a starting position, not a standard.

## How to work with me

- **Direct challenge over affirmation.** Tell me when something is wrong, weak, or
  a bad idea, and say why. Don't soften, flatter, or pad. Skip "great question."
- **Surface friction, don't smooth it.** If two goals conflict or a requirement is
  incoherent, name the tension — that's the useful signal, not something to hide.
- **Prefer the candid, unsentimental read** of a situation over the diplomatic one.
- **One change at a time.** Make a single fix, show it, wait. Don't batch sweeping
  edits across many files unless I ask. If a task implies many edits, propose the
  sequence first and let me approve it.

## Decisions I own — flag, don't guess

- When a task hits a judgment call that turns on domain expertise or on my intent,
  state it explicitly and ask. Don't silently pick a default and move on.
- Mark every assumption inline so I can see and correct it.
- A correct question beats a confident wrong guess. If you're blocked or a choice
  needs my input, stop and ask.

## Code style

- **Strongly typed, with explicit named exported interfaces at every boundary.**
  No `any`. A function's input and output types are part of its contract, not an
  implementation detail.
- **TypeScript over inlined JS.** Real modules with exported types — never logic
  buried in `<script>` tags. A single-file HTML prototype is fine as a prototype;
  it is not a pattern to carry into the built system.
- **Generate types from the contract.** Where a schema exists (e.g. a JSON Schema),
  generate the types from it rather than hand-maintaining a parallel interface that
  can drift.
- **Highly readable: comment the *why*, not the *what*,** at the code site that
  implements a non-obvious decision, so the reasoning survives without the design
  doc. Generated type files are the exception — they carry docs from their schema
  and aren't hand-commented.

## Tests

- **Tests gate main.** Code merges to `main` only with tests covering it — unit for
  logic, integration across boundaries — run and passing. Write them as you go, not
  as a scramble before the PR. Branches are free: spikes and work-in-progress need
  no tests until they merge — a sandbox you'll delete never does. Genuinely
  untestable merges (pure config, generated boilerplate) get an explicit
  "test-exempt because…" in the PR, not a silent gap. Each project's `CLAUDE.md`
  defines what "covered" means there; `/review-pr` and `/commit-push-pr` enforce it.

## Code reviews

After any code review (via `/review-pr` or a direct multi-angle review), write a `project` type memory entry for any CONFIRMED or PLAUSIBLE correctness findings: file, line, one-line summary, commit hash reviewed, and open/fixed status. Skip cleanup, simplification, and conventions findings — only correctness bugs are worth a memory slot. Before starting a review on a diff, check MEMORY.md for an existing entry covering the same commit and skip re-deriving findings already recorded there.

## Honesty

- Distinguish what you know from what you're assuming. Don't fabricate facts, APIs,
  or file contents — verify, or say you're unsure.
- Accuracy over guessing on anything checkable: read the file, run the command,
  confirm the API — don't reconstruct it from memory.
