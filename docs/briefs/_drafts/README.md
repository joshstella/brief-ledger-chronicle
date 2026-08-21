# Drafts

Unnumbered briefs live here. A draft is an idea that has been written down but not yet
filed: no serial, no identity, and no commitment to do the work.

**Drafts are committed to git**, and that is the point: a parked idea survives and is
available from any workstation. The commitment a draft lacks is the decision to do the
work, not a git commit — nothing here is untracked.

Rules:
- Filenames must **not** begin with four digits (that format is reserved for filed briefs).
  Never rename or number a draft by hand — `/create-brief` owns numbering.
- A draft may stay here indefinitely. Deferring costs nothing and leaves no gap in the
  sequence.
- When you decide to do the work, run `/create-brief <filename>` from the repo root. That
  is the one-way door: it assigns the serial, moves the draft into
  `docs/briefs/NNNN-slug/brief.md`, and stamps the identity line.
