/** GENERATED FILE - do not edit by hand. Source: schema/read-surface.schema.json. Regenerate with: npm run types */

/**
 * How the instrument classified a commit. Closed set: read.sh assigns exactly these and falls through to "code" rather than guessing.
 */
export type EventKind = "phase" | "close" | "filed" | "declaration" | "record" | "code";

/**
 * The shape of experiments/blic/read.sh output, as observed against this repository's 39 briefs. This schema is a description of the frozen instrument, not a contract it agreed to: read.sh is hand-rolled JSON with no schema of its own, so every field here was read out of the script and confirmed against a live snapshot. Where the instrument disagrees with the five-state vocabulary in docs/blc/briefs/README.md, this schema records what the instrument actually emits and the disagreement is carried in a description.
 */
export interface ReadSurface {
  snapshot?: Snapshot;
  peerEvent?: PeerEvent;
}
/**
 * read.sh snapshot. Everything a console needs in one document.
 */
export interface Snapshot {
  /**
   * UTC timestamp of the read, not of the record.
   */
  generated: string;
  /**
   * Absolute path of the repository root the instrument read.
   */
  repo: string;
  me: Identity;
  head: string;
  branch: string;
  briefs: Brief[];
  declarations: Declaration[];
  defects: Defect[];
  events: RecordEvent[];
}
/**
 * read.sh me
 */
export interface Identity {
  /**
   * git config user.email, or empty when git has no identity configured.
   */
  email: string;
}
/**
 * One numbered brief. Identity fields come from brief.md, state from ledger.md. A brief with no ledger is reported rather than skipped.
 */
export interface Brief {
  /**
   * Zero-padded serial, e.g. 0039.
   */
  serial: string;
  /**
   * Directory name, serial-slug.
   */
  slug: string;
  /**
   * Path relative to the repository root.
   */
  dir: string;
  /**
   * First H1 of brief.md, falling back to the slug.
   */
  title: string;
  /**
   * Raw brief state from the status line. NOT the five-state vocabulary: for older briefs the merge pointer is glued on, e.g. "done(PR#11)" or "done(commit 92a7168)". Normalize before display or before comparing.
   */
  state: string;
  /**
   * The whole status line, verbatim. Empty when the ledger has none, in which case state is "no-line".
   */
  status_line: string;
  /**
   * **Owner:** from the identity line. Empty when absent.
   */
  owner: string;
  /**
   * **Author:** from the identity line.
   */
  author: string;
  /**
   * Owner, or Author when there is no Owner. The rule list-briefs.sh --owner uses.
   */
  assignee: string;
  /**
   * assignee equals the current git identity, case-insensitively.
   */
  mine: boolean;
  /**
   * **Created:** timestamp. Format varies across three years of convention.
   */
  created: string;
  /**
   * **Closed:** date from the ledger. Empty when the ledger records none, which for a done brief is the BRIEFS-11 judgment.
   */
  closed: string;
  /**
   * Commit date of the last commit to touch the brief directory, ISO 8601 with offset. Empty when git knows nothing about the path.
   */
  touched: string;
  has_ledger: boolean;
  phases: Phase[];
}
/**
 * One phase entry. Its state comes from the ledger status line and its label from the phase table; the two can disagree, which is BRIEFS-9, and the instrument reports both rather than correcting either.
 */
export interface Phase {
  /**
   * Phase id as written in the status line: a letter for modern briefs, a digit for the earliest ones.
   */
  id: string;
  /**
   * Phase label from the ledger's phase table. Empty for the oldest briefs, which have no table.
   */
  label: string;
  /**
   * Raw phase state token. Usually one of pending / in-progress / done / skipped / blocked, but the instrument's tokenizer splits on whitespace, so a pointer containing a space leaks into this field as the truncated token "done(commit". Normalize before display.
   */
  state: string;
  /**
   * Merge pointer, e.g. PR#45. Empty when the phase has none, and also empty when the tokenizer lost it to a space.
   */
  pointer: string;
}
/**
 * One contributor's claim on work picked up and not yet filed. Only files carrying at least one ## entry appear.
 */
export interface Declaration {
  /**
   * Declaration file basename, which is the contributor's git email.
   */
  who: string;
  mine: boolean;
  touched: string;
  claims: string[];
}
/**
 * One line of tools/validate-briefs.sh output, parsed. The gate's own judgment, not a second reading of it.
 */
export interface Defect {
  /**
   * Contract clause id, e.g. BRIEFS-11.
   */
  clause: string;
  /**
   * judgment or violation, as the gate classified it.
   */
  kind: string;
  /**
   * Usually the brief slug the judgment is about.
   */
  subject: string;
  message: string;
}
/**
 * One commit, classified. read.sh events.
 */
export interface RecordEvent {
  /**
   * First eight hex characters.
   */
  sha: string;
  /**
   * Commit date, ISO 8601 with offset.
   */
  when: string;
  /**
   * Author email.
   */
  who: string;
  /**
   * True for every real event in this fixture: the repository has one author.
   */
  mine: boolean;
  kind: EventKind;
  /**
   * Brief serial the commit names, or empty.
   */
  serial: string;
  /**
   * Phase letter the commit names, or empty.
   */
  phase: string;
  subject: string;
}
/**
 * One line of experiments/blic/peer-events.sh. Carries synthetic: true, which nothing removes. It has no "when": the generator emits none, so a consumer that wants a timestamp must stamp arrival and say so.
 */
export interface PeerEvent {
  sha: string;
  who: string;
  mine: boolean;
  synthetic: true;
  kind: EventKind;
  serial: string;
  phase: string;
  subject: string;
}
