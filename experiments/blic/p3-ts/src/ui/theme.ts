import type { EventKind } from '../read-surface/generated/read-surface.js';
import type { RecordState } from '../model/state.js';

/** Colour per record state. Off-vocabulary states get `magenta` so they cannot pass as normal. */
export const STATE_COLOUR: Readonly<Record<RecordState, string>> = {
  pending: 'gray',
  'in-progress': 'cyan',
  deferred: 'yellow',
  done: 'green',
  skipped: 'gray',
};

export const OFF_VOCABULARY_COLOUR = 'magenta';

export const KIND_COLOUR: Readonly<Record<EventKind, string>> = {
  phase: 'cyan',
  close: 'green',
  filed: 'blue',
  declaration: 'yellow',
  record: 'white',
  code: 'gray',
};

/** Fixed width so the kind column does not jitter as lines arrive. */
export function kindTag(kind: EventKind): string {
  return kind.toUpperCase().padEnd(11, ' ');
}

export function stateColour(state: RecordState | undefined): string {
  return state === undefined ? OFF_VOCABULARY_COLOUR : STATE_COLOUR[state];
}

export function shortTime(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '--:--:--';
  return date.toTimeString().slice(0, 8);
}

export function shortDate(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '----------';
  return date.toISOString().slice(0, 10);
}
