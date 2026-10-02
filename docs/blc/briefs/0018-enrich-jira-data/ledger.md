# Ledger — #0018 The Jira export carries what the brief says, not only where it is

`blc/2 #0018 in-progress a:done(PR#88) b:done(PR#89) c:in-progress(PR#90)`

**Brief:** `docs/blc/briefs/0018-enrich-jira-data/brief.md`
**Started:** 2026-10-02
**Status:** in-progress

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the sources | done (PR#88) | — |
| b | the descriptions | done (PR#89) | — |
| c | the wiki markup | in-progress (PR#90) | `brief/0018-c-the-wiki-markup` |

The brief has two phases, `a` and `b`. Its `b` is split here into `b` and `c` (decision 3).

**a — the sources.** README, "Reporting to a tracker": the brief's summary is its
`## The claim` section, and a phase's description is the ledger paragraph that begins
`**<id> — <label>.**` and runs to the next blank line. Say that "Map field value" must stay
unticked for Description, because it removes every line break. `blc-start-brief` step 6 writes
one such paragraph for each phase it plans. No program changes, and no Contract clause. What
the export does with the sources is documented in `b`, with the code, so the README does not
describe an export that does not exist yet.

**b — the descriptions.** `tools/jira-csv.sh` puts the claim section, then the brief path, in
the Epic's Description (decision 5). It puts each phase's paragraph, without its bold
`**<id> — <label>.**` lead, then the ledger path, in that Task's Description. The text is copied
as it is in the record. A missing claim or paragraph gives the paths alone and one warning on
stderr for each. README: what the export copies, what a missing source gives, and that the
Description is a copy from the import date. Tests: claim present and missing, paragraph present
and missing for each phase, a quote, a comma and a newline inside the text, the whole-export
comparison updated, and the existing refusals still writing nothing to stdout.

**c — the wiki markup.** The copied text is converted from markdown to Jira wiki markup:
`**bold**` to `*bold*`, `*italic*` to `_italic_`, `` `code` `` to `{{code}}`, `[text](url)`
to `[text|url]`, a markdown table to a wiki table (header cells `||`, separator row dropped),
and the lines of one paragraph joined into one line. List items and table rows keep their own
lines. Text inside a code span is not converted. Tests for each construct, for code that holds
asterisks, and for a fixture claim that holds a table and italics, as the claims of #0008 and
#0012 do. `c`
closes only after one import by hand into a Jira Cloud site shows the result.

## Dependency structure

A strict chain: `a → b → c`. `b` reads the sources that `a` names. `c` converts the text that
`b` copies. Each phase branch writes this ledger's status line, so phases do not run in
parallel.

Between `b` and `c` an export carries raw markdown into Jira. No brief has been imported, so
that state reaches no board.

## Open decisions

| # | decision | blocks |
|---|---|---|
| 1 | **Settled 2026-10-02: no length limit.** From the brief. The longest claim section in the repository is about 1,500 characters. Rejected: a cap with a marked cut. | `b` |
| 2 | **Settled 2026-10-02: the conversion covers italic, tables and wrapped lines too.** The brief settled bold, code and links, and "everything else stays as text". A scan of the claim sections at start showed that list misses three things. Markdown `*italic*` is wiki bold, and #0008, #0012 and #0014 use it. The claims of #0008 and #0012 hold markdown tables, and a wiki renderer reads any line starting with a pipe as a table row, so the separator row shows as dashes. Every paragraph is wrapped at about 95 columns, and a wiki renderer is understood to show a single newline as a line break. That last point is from memory of the wiki format, not a source, and the import in `c` checks it. Rejected: italic and joining only, and the settled list unchanged. | `c` |
| 3 | **Settled 2026-10-02: the brief's `b` is two phases.** Copying the text and converting it are separate work, each with its own tests. With decision 2, one phase is too large to review in one sitting. Rejected: the brief's two phases. | — |
| 4 | **Settled 2026-10-02: two paragraphs for one phase stop the export.** The export already refuses a phase with two candidate rows, because it cannot tell which one is meant. Two paragraphs are the same case. Two `## The claim` sections in one brief are too. Rejected: take the first, which exports a guess. | `b` |
| 5 | **Settled 2026-10-02: the paths stay as they are.** The brief says the Epic gets "the two paths". The export writes the brief path in the Epic and the ledger path in each Task, and the brief misread that. The text goes before the path that is there now, so a brief with no named sources exports exactly as before. | `b` |
| 6 | **Settled 2026-10-02: headings convert, and code spans escape wiki characters.** Two additions to decision 2, found while building `c`. A `### x` line is a numbered list item in wiki markup, and `b`'s own test showed that a claim can hold one, so it becomes `h3. x`. The renderer is understood to read wiki formatting inside `{{...}}`, so `{{--max-age}}` could show struck through. Inside a code span, each wiki formatting character gets a backslash. The import by hand checks both. | `c` |

## Scope

**Settled 2026-10-02: this is for briefs filed from now on.** No existing brief is exported, so
`a` adds no paragraphs to old ledgers, and 9 of the 17 have none. A brief started after `a`
gets a paragraph for each phase from `blc-start-brief`. For such a brief, a missing paragraph
means a step was skipped, and the warning in `b` says so.

## Complications

- No existing ledger has two paragraphs for the same phase. **Settled in `b`:** the export
  refuses one (decision 4).
- No claim section has a `{`, a line starting with `#`, or a link. Each would mean something in
  wiki markup that `c` does not convert. A later brief that adds one exports it wrong.
- `skills/blc-start-brief/SKILL.md` is the one copy. `.cursor/skills` is a symbolic link to
  `skills/`.
