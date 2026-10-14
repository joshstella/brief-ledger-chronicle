/**
 * The status vocabulary of docs/blc/briefs/README.md:103-109. Five states and nothing else.
 * The instrument emits strings that are not in this set, and that gap is the point: a reader
 * that treats `state` as free text cannot tell a convention from a typo.
 */
export const RECORD_STATES = ['pending', 'in-progress', 'deferred', 'done', 'skipped'] as const;

export type RecordState = (typeof RECORD_STATES)[number];

/** What a state string turned out to be once the instrument's glued-on pointer came off. */
export interface ParsedState {
  /** The state, when it is one of the five. */
  readonly state: RecordState | undefined;
  /** Pointer recovered from the state string, e.g. `PR#11` out of `done(PR#11)`. */
  readonly pointer: string;
  /**
   * The token opened a pointer and never closed it, so the instrument's tokenizer cut it at a
   * space. What is left is a fragment, not a pointer, and it is not reported as one.
   */
  readonly pointerTruncated: boolean;
  /** The string as the instrument gave it. */
  readonly raw: string;
  /**
   * Why this string is not in the vocabulary, when it is not. `planned` and `no-line` arrive
   * here: neither is one of the five, and `planned` is the one tools/list-briefs.sh invents.
   */
  readonly offVocabulary: string | undefined;
}

function isRecordState(value: string): value is RecordState {
  return (RECORD_STATES as readonly string[]).includes(value);
}

/**
 * Split `done(PR#11)` and `done(commit 92a7168)` into a state and a pointer, and say so when
 * what is left is not one of the five. The instrument reports brief state with the pointer
 * still attached, so every consumer has to do this and only a typed one has to do it once.
 */
export function parseState(raw: string): ParsedState {
  const trimmed = raw.trim();
  const open = trimmed.indexOf('(');
  const head = open === -1 ? trimmed : trimmed.slice(0, open);
  const truncated = open !== -1 && !trimmed.endsWith(')');
  const tail = open === -1 || truncated ? '' : trimmed.slice(open + 1).replace(/\)$/, '');

  if (isRecordState(head)) {
    return { state: head, pointer: tail, pointerTruncated: truncated, raw: trimmed, offVocabulary: undefined };
  }
  return {
    state: undefined,
    pointer: tail,
    pointerTruncated: truncated,
    raw: trimmed,
    offVocabulary:
      trimmed === 'no-line'
        ? 'ledger has no status line'
        : trimmed === 'planned'
          ? 'state `planned` is not in the five-state vocabulary'
          : `state \`${trimmed}\` is not in the five-state vocabulary`,
  };
}
