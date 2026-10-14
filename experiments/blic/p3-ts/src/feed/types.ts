import type { EventKind, PeerEvent, RecordEvent } from '../read-surface/generated/read-surface.js';

/**
 * Where a feed line came from. This is a discriminated union and not a boolean flag because
 * the two sources carry different fields — a peer event has no commit date — and because the
 * README is explicit that showing a synthetic event unmarked is a lie about the record. A
 * union makes the unmarked case fail to compile rather than fail to be noticed.
 */
export type FeedProvenance =
  | { readonly source: 'record'; readonly event: RecordEvent }
  | { readonly source: 'synthetic'; readonly event: PeerEvent };

export interface FeedEntry {
  /** Stable key: the sha is unique inside a run, and peer shas repeat across stream cycles. */
  readonly key: string;
  readonly sha: string;
  readonly who: string;
  readonly mine: boolean;
  readonly kind: EventKind;
  readonly serial: string;
  readonly phase: string;
  readonly subject: string;
  /**
   * For a record event, the commit date. For a synthetic one, the time this console saw the
   * line, because peer-events.sh emits no timestamp. `whenIsArrival` says which.
   */
  readonly when: string;
  readonly whenIsArrival: boolean;
  readonly provenance: FeedProvenance;
}

export function fromRecordEvent(event: RecordEvent): FeedEntry {
  return {
    key: `record:${event.sha}`,
    sha: event.sha,
    who: event.who,
    mine: event.mine,
    kind: event.kind,
    serial: event.serial,
    phase: event.phase,
    subject: event.subject,
    when: event.when,
    whenIsArrival: false,
    provenance: { source: 'record', event },
  };
}

export function fromPeerEvent(event: PeerEvent, arrivedAt: Date, sequence: number): FeedEntry {
  return {
    key: `synthetic:${event.sha}:${sequence}`,
    sha: event.sha,
    who: event.who,
    mine: event.mine,
    kind: event.kind,
    serial: event.serial,
    phase: event.phase,
    subject: event.subject,
    when: arrivedAt.toISOString(),
    whenIsArrival: true,
    provenance: { source: 'synthetic', event },
  };
}

export function isSynthetic(entry: FeedEntry): boolean {
  return entry.provenance.source === 'synthetic';
}
