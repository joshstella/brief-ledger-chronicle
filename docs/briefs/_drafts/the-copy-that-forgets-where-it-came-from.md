# The copy that forgets where it came from

**Created:** 2026-09-29T18:52:00Z · **Author:** josh.stella@gmail.com
**Depends on:** #0012

## The finding

`install.sh` project mode copies the toolkit into a target repository. Nothing in the copy
records which version of the toolkit it is.

Machine mode is the opposite and is not the subject here: it symlinks into a checkout, so what
a machine runs is whatever that checkout currently holds, and `git log` answers the question
directly. Project mode writes real files with `cp`, and `cp` carries no provenance.

From inside an installed project you cannot answer:

- which commit of the toolkit produced these files
- which Contract version the shipped `tools/validate-briefs.sh` decides
- whether a re-run of `install.sh` would change anything
- whether two projects are running the same toolkit

`docs/install-log/` records that an install happened. It does not record what was installed.

## Why it has not been a problem

One user, one machine, one checkout. The toolkit a project has is the toolkit the author was
working on that day, and the author remembers. Everything needed to answer the questions above
is in a human's head, and that human is also the only person asking.

That is the assumption that ends the moment a second person installs this, and it ends quietly:
nothing fails, a project simply carries an unidentifiable copy and no one notices until two
copies disagree.

## The shape of a fix — not decided

Something the installer writes and the tools can read. Candidates, in rough order of cost:

- A stamp file under `docs/` or beside the tools, holding the toolkit commit and the Contract
  version the shipped validator decides.
- The same, plus a `--version` on the installed tools that prints it.
- The same, plus a check that reports when the installed copy is older than the source it was
  installed from.

Open questions a brief would have to settle:

1. Is the stamp a fact about the source (which commit) or about the contract (which clause set),
   or both? They answer different questions and can drift apart.
2. Does anything **enforce** the stamp, or is it a report? A gate on version skew is a gate a
   project cannot pass without network or filesystem access to the source, which #0011 says a
   project may not be made to depend on.
3. Does a stamped copy change what `install.sh` does on re-run? Today every toolkit-owned tree
   is replaced unconditionally. A stamp makes "already current" expressible for the first time,
   and that is a behaviour change, not a label.
4. Is the machine-mode symlink path in scope at all? It has no version question, so including
   it may mean inventing one.

## Why this is a draft and not a brief

It has no deadline and no victim yet. Filing it now would put a serial on a problem whose shape
is still decided by question 1, and the cost of being wrong about question 1 is a stamp that
answers neither question well. It is written down because the condition that makes it urgent —
a second person, a second machine — is expected rather than hypothetical, and the finding would
otherwise live only in a conversation.
