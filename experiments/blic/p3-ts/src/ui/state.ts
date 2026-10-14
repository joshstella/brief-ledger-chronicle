import type { Snapshot } from '../read-surface/generated/read-surface.js';
import type { SchemaViolation } from '../read-surface/validate.js';
import type { BriefViewIndex, BriefView } from '../model/brief-view.js';
import { indexBriefs } from '../model/brief-view.js';
import type { FeedEntry } from '../feed/types.js';

/** Which set of briefs the list is showing. */
export type BriefFilter = 'mine-open' | 'in-flight' | 'judged' | 'all';

export const FILTER_ORDER: readonly BriefFilter[] = ['mine-open', 'in-flight', 'judged', 'all'];

export const FILTER_LABEL: Readonly<Record<BriefFilter, string>> = {
  'mine-open': 'mine · open',
  'in-flight': 'in flight',
  judged: 'gate judgments',
  all: 'all',
};

export type Pane = 'briefs' | 'feed';

/** How many feed lines are kept. A day-long session would otherwise grow without bound. */
export const FEED_LIMIT = 200;

export interface ConsoleState {
  readonly snapshot: Snapshot | undefined;
  readonly index: BriefViewIndex | undefined;
  readonly filter: BriefFilter;
  /** Index into the filtered list, not into the snapshot. */
  readonly selected: number;
  readonly pane: Pane;
  readonly feed: readonly FeedEntry[];
  readonly feedPaused: boolean;
  /** Lines held back while paused, so pausing does not look like silence. */
  readonly heldWhilePaused: readonly FeedEntry[];
  /** Events seen since the console opened. The "what changed that I did not do" counter. */
  readonly arrivedSinceOpen: number;
  readonly arrivedNotMine: number;
  readonly syntheticSeen: number;
  readonly violations: readonly SchemaViolation[];
  readonly errors: readonly string[];
  readonly lastReadMs: number;
  readonly lastReadAt: string | undefined;
  readonly reading: boolean;
}

export const initialState: ConsoleState = {
  snapshot: undefined,
  index: undefined,
  filter: 'mine-open',
  selected: 0,
  pane: 'briefs',
  feed: [],
  feedPaused: false,
  heldWhilePaused: [],
  arrivedSinceOpen: 0,
  arrivedNotMine: 0,
  syntheticSeen: 0,
  violations: [],
  errors: [],
  lastReadMs: 0,
  lastReadAt: undefined,
  reading: true,
};

export type ConsoleAction =
  | { readonly type: 'snapshot'; readonly snapshot: Snapshot; readonly violations: readonly SchemaViolation[]; readonly elapsedMs: number }
  | { readonly type: 'feed'; readonly entries: readonly FeedEntry[]; readonly violations: readonly SchemaViolation[] }
  | { readonly type: 'error'; readonly message: string }
  | { readonly type: 'reading'; readonly reading: boolean }
  | { readonly type: 'move'; readonly delta: number; readonly visibleCount: number }
  | { readonly type: 'select'; readonly index: number }
  | { readonly type: 'cycle-filter' }
  | { readonly type: 'cycle-pane' }
  | { readonly type: 'toggle-pause' };

export function visibleBriefs(state: ConsoleState): readonly BriefView[] {
  const index = state.index;
  if (index === undefined) return [];
  switch (state.filter) {
    case 'mine-open':
      return index.byMine.filter((v) => v.open);
    case 'in-flight':
      return index.inFlight;
    // The brief names sixteen BRIEFS-11 judgments as the thing a console should surface on
    // open. They are all on `done` briefs, so no filter over open work can reach them.
    case 'judged':
      return index.all.filter((v) => v.defects.length > 0);
    case 'all':
      return index.all;
    default:
      return index.all;
  }
}

function clamp(value: number, max: number): number {
  if (max <= 0) return 0;
  return Math.max(0, Math.min(value, max - 1));
}

export function reducer(state: ConsoleState, action: ConsoleAction): ConsoleState {
  switch (action.type) {
    case 'snapshot': {
      const index = indexBriefs(action.snapshot);
      return {
        ...state,
        snapshot: action.snapshot,
        index,
        violations: action.violations,
        lastReadMs: action.elapsedMs,
        lastReadAt: action.snapshot.generated,
        reading: false,
      };
    }
    case 'feed': {
      const notMine = action.entries.filter((e) => !e.mine).length;
      const synthetic = action.entries.filter((e) => e.provenance.source === 'synthetic').length;
      const counted: ConsoleState = {
        ...state,
        arrivedSinceOpen: state.arrivedSinceOpen + action.entries.length,
        arrivedNotMine: state.arrivedNotMine + notMine,
        syntheticSeen: state.syntheticSeen + synthetic,
        violations: action.violations.length > 0 ? [...state.violations, ...action.violations] : state.violations,
      };
      if (state.feedPaused) {
        return { ...counted, heldWhilePaused: [...action.entries, ...state.heldWhilePaused].slice(0, FEED_LIMIT) };
      }
      return { ...counted, feed: [...action.entries, ...state.feed].slice(0, FEED_LIMIT) };
    }
    case 'error':
      return { ...state, errors: [action.message, ...state.errors].slice(0, 20), reading: false };
    case 'reading':
      return { ...state, reading: action.reading };
    case 'move':
      return { ...state, selected: clamp(state.selected + action.delta, action.visibleCount) };
    case 'select':
      return { ...state, selected: Math.max(0, action.index) };
    case 'cycle-filter': {
      const next = FILTER_ORDER[(FILTER_ORDER.indexOf(state.filter) + 1) % FILTER_ORDER.length] ?? 'all';
      return { ...state, filter: next, selected: 0 };
    }
    case 'cycle-pane':
      return { ...state, pane: state.pane === 'briefs' ? 'feed' : 'briefs' };
    case 'toggle-pause':
      // Releasing the pause replays what was held rather than dropping it: a feed that loses
      // lines while you read one of them is worse than no feed, because you trust it.
      return state.feedPaused
        ? { ...state, feedPaused: false, feed: [...state.heldWhilePaused, ...state.feed].slice(0, FEED_LIMIT), heldWhilePaused: [] }
        : { ...state, feedPaused: true };
    default:
      return state;
  }
}
