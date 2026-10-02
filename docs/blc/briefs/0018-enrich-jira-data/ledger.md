# Ledger — #0018 The Jira export carries what the brief says, not only where it is

`blc/2 #0018 pending a:pending b:pending c:pending`

**Brief:** `docs/blc/briefs/0018-enrich-jira-data/brief.md`
**Started:** 2026-10-02
**Status:** pending

## Phases

| id | label | status | branch |
|---|---|---|---|
| a | the sources | pending | — |
| b | the descriptions | pending | — |
| c | the wiki markup | pending | — |

The brief has two phases, `a` and `b`. Its `b` is split here into `b` and `c` (decision 3).

**a — the sources.** README, "Reporting to a tracker": the brief's summary is its
`## The claim` section, and a phase's description is the ledger paragraph that begins
`**<id> — <label>.**` and runs to the next blank line. Say what the export does when one is
missing, that the Description is a copy from the import date, and that "Map field value" must
stay unticked for Description, because it removes every line break. `blc-start-brief` step 6
writes one such paragraph for each phase it plans. No program changes, and no Contract clause.

**b — the descriptions.** `tools/jira-csv.sh` puts the claim section, then the brief and ledger
paths, in the Epic's Description. It puts each phase's paragraph, without its bold
`**<id> — <label>.**` lead, then the ledger path, in that Task's Description. The text is copied
as it is in the record. A missing claim or paragraph gives the paths alone and one warning on
stderr for each. Tests: claim present and missing, paragraph present and missing for each
phase, a quote, a comma and a newline inside the text, the whole-export comparison updated, and
the existing refusals still writing nothing to stdout.

**c — the wiki markup.** The copied text is converted from markdown to Jira wiki markup:
`**bold**` to `*bold*`, `*italic*` to `_italic_`, `` `code` `` to `{{code}}`, `[text](url)`
to `[text|url]`, a markdown table to a wiki table (header cells `||`, separator row dropped),
and the lines of one paragraph joined into one line. List items and table rows keep their own
lines. Text inside a code span is not converted. Tests for each construct, for code that holds
asterisks, and for the claim sections of #0008 and #0012, which hold tables and italics. `c`
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

## Complications

- 8 of 17 existing ledgers have phase paragraphs. The other 9 export their Tasks with paths
  only and a warning for each phase. `a` does not add paragraphs to old ledgers.
- No existing ledger has two paragraphs for the same phase. `b` still has to decide what one
  does: the export refuses an ambiguous phase row today, and the same rule fits here.
- No claim section has a `{`, a line starting with `#`, or a link. Each would mean something in
  wiki markup that `c` does not convert. A later brief that adds one exports it wrong.
- `skills/blc-start-brief/SKILL.md` is the one copy. `.cursor/skills` is a symbolic link to
  `skills/`.
