import type { Brief, Defect, Phase, Snapshot } from '../read-surface/generated/read-surface.js';
import { parseState } from './state.js';
import type { ParsedState } from './state.js';

/** A phase with its state parsed and its pointer recovered from wherever it was hiding. */
export interface PhaseView {
  readonly id: string;
  readonly label: string;
  readonly parsed: ParsedState;
  /** Pointer from the instrument's own field, falling back to one recovered from the state. */
  readonly pointer: string;
}

/**
 * What the console says to do next. `confidence` is the honest part: the brief asks whether a
 * next action is derivable at all, and most of the time the ledger supports only `observed`.
 */
export interface NextAction {
  readonly text: string;
  /**
   * `derived` — the ledger says enough to name an action.
   * `observed` — all the record supports is a restatement of state.
   * `none` — nothing is owed.
   */
  readonly confidence: 'derived' | 'observed' | 'none';
  /** Field or file the action was read out of, so a reader can check it. */
  readonly basis: string;
}

/** One thing this brief's own record says about itself that does not hold together. */
export interface BriefLint {
  readonly clause: string;
  readonly message: string;
}

export interface BriefView {
  readonly brief: Brief;
  readonly parsed: ParsedState;
  readonly phases: readonly PhaseView[];
  readonly nextAction: NextAction;
  /** Gate output for this brief, matched by slug. */
  readonly defects: readonly Defect[];
  /** Disagreements this console found, kept apart from the gate's own judgments. */
  readonly lints: readonly BriefLint[];
  /** Open means: not done, not skipped. The filter "in flight" narrows this further. */
  readonly open: boolean;
  readonly inFlight: boolean;
}

function toPhaseView(phase: Phase): PhaseView {
  const parsed = parseState(phase.state);
  return {
    id: phase.id,
    label: phase.label,
    parsed,
    pointer: phase.pointer !== '' ? phase.pointer : parsed.pointer,
  };
}

/**
 * Derive the next action from the ledger alone. The rules are the project's own: a phase in
 * flight is finished and committed through blc-commit-push-pr, the phase after a finished one
 * is opened with blc-next-brief-phase, a brief whose phases are all closed is closed with
 * blc-close-brief, and a filed serial with no ledger is started with blc-start-brief.
 */
function deriveNextAction(brief: Brief, phases: readonly PhaseView[], parsed: ParsedState): NextAction {
  if (!brief.has_ledger) {
    return {
      text: 'no ledger: run blc-start-brief to plan phases and branch the first one',
      confidence: 'derived',
      basis: 'has_ledger=false',
    };
  }
  if (parsed.raw === 'no-line') {
    return {
      text: 'ledger has no status line: nothing can read this brief cheaply',
      confidence: 'derived',
      basis: 'status_line is empty',
    };
  }

  const flight = phases.find((p) => p.parsed.state === 'in-progress');
  if (flight !== undefined) {
    const branch = flight.pointer !== '' ? flight.pointer : 'the branch it does not name';
    return {
      text: `finish phase ${flight.id} on ${branch}, then blc-review-pr and blc-commit-push-pr`,
      confidence: flight.pointer !== '' ? 'derived' : 'observed',
      basis: `phase ${flight.id} is in-progress`,
    };
  }

  const deferred = phases.find((p) => p.parsed.state === 'deferred');
  if (deferred !== undefined) {
    return {
      text: `phase ${deferred.id} is parked: resume it or record why it stays parked`,
      confidence: 'observed',
      basis: `phase ${deferred.id} is deferred`,
    };
  }

  const pending = phases.find((p) => p.parsed.state === 'pending');
  if (pending !== undefined) {
    return {
      text: `open phase ${pending.id}${pending.label !== '' ? ` (${pending.label})` : ''} with blc-next-brief-phase`,
      confidence: 'derived',
      basis: `phase ${pending.id} is pending and no phase is in flight`,
    };
  }

  if (parsed.state === 'done' && brief.closed === '') {
    return {
      text: 'status says done and the ledger has no Closed date: run blc-close-brief',
      confidence: 'derived',
      basis: 'BRIEFS-11',
    };
  }
  if (parsed.state === 'done' || parsed.state === 'skipped') {
    return { text: '', confidence: 'none', basis: parsed.raw };
  }

  return {
    text: `status is ${parsed.raw} and no phase is open: the ledger does not say what comes next`,
    confidence: 'observed',
    basis: 'status line vs phase states',
  };
}

function lint(brief: Brief, phases: readonly PhaseView[], parsed: ParsedState): readonly BriefLint[] {
  const lints: BriefLint[] = [];

  if (parsed.offVocabulary !== undefined) {
    lints.push({ clause: 'vocabulary', message: parsed.offVocabulary });
  }
  for (const phase of phases) {
    if (phase.parsed.offVocabulary !== undefined) {
      lints.push({ clause: 'vocabulary', message: `phase ${phase.id}: ${phase.parsed.offVocabulary}` });
    }
    // The status line and the phase table are written in one edit by a person, so the table
    // missing a row the line names is the BRIEFS-9 disagreement the instrument reports both
    // halves of rather than correcting.
    if (phase.label === '' && brief.has_ledger) {
      lints.push({ clause: 'BRIEFS-9', message: `phase ${phase.id} is in the status line and not in the phase table` });
    }
    // Not a defect in the record. The instrument's tokenizer split `done(commit 92a7168)` on
    // the space, so the pointer never reached this process. Reported against the reader.
    if (phase.parsed.pointerTruncated) {
      lints.push({ clause: 'instrument', message: `phase ${phase.id}: read.sh lost the pointer to a space` });
    }
  }
  if (parsed.state === 'done' && phases.some((p) => p.parsed.state === 'in-progress')) {
    lints.push({ clause: 'BRIEFS-9', message: 'brief is done and a phase is still in-progress' });
  }
  return lints;
}

export function buildBriefView(brief: Brief, defects: readonly Defect[]): BriefView {
  const parsed = parseState(brief.state);
  const phases = brief.phases.map(toPhaseView);
  const open = parsed.state !== 'done' && parsed.state !== 'skipped';
  return {
    brief,
    parsed,
    phases,
    nextAction: deriveNextAction(brief, phases, parsed),
    defects: defects.filter((d) => d.subject === brief.slug),
    lints: lint(brief, phases, parsed),
    open,
    // In flight means a phase is actually moving, which is a stronger claim than open: a
    // filed serial with no ledger is open and nothing is moving.
    inFlight: phases.some((p) => p.parsed.state === 'in-progress' || p.parsed.state === 'deferred'),
  };
}

export interface BriefViewIndex {
  readonly all: readonly BriefView[];
  readonly byMine: readonly BriefView[];
  readonly open: readonly BriefView[];
  readonly inFlight: readonly BriefView[];
  /** Gate judgments whose subject matched no brief slug. */
  readonly unmatchedDefects: readonly Defect[];
}

export function indexBriefs(snapshot: Snapshot): BriefViewIndex {
  const all = snapshot.briefs.map((b) => buildBriefView(b, snapshot.defects));
  const matched = new Set(all.flatMap((v) => v.defects.map((d) => `${d.clause}:${d.subject}:${d.message}`)));
  return {
    all,
    byMine: all.filter((v) => v.brief.mine),
    open: all.filter((v) => v.open),
    inFlight: all.filter((v) => v.inFlight),
    unmatchedDefects: snapshot.defects.filter((d) => !matched.has(`${d.clause}:${d.subject}:${d.message}`)),
  };
}
