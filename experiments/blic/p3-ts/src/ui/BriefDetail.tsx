import React from 'react';
import { Box, Text } from 'ink';
import type { BriefView } from '../model/brief-view.js';
import { shortDate, stateColour } from './theme.js';

export interface BriefDetailProps {
  readonly view: BriefView | undefined;
  readonly width: number;
  /** Rows the pane may use. Exceeding it makes Ink overlap lines rather than scroll. */
  readonly rows: number;
}

/**
 * Rows the fixed part of the pane always takes: the title, seven identity rows, three NEXT
 * rows, the PHASES / DEFECTS / LINTS headings, three blank separators, the status line, and
 * the two "… more" lines the lists can add. Ink overlaps rather than scrolls when a column
 * overflows, so this is counted rather than guessed at.
 */
const CHROME_ROWS = 21;

function Row({ label, value }: { readonly label: string; readonly value: string }): React.JSX.Element {
  return (
    <Text wrap="truncate-end">
      <Text dimColor>{label.padEnd(9)}</Text>
      <Text>{value}</Text>
    </Text>
  );
}

export function BriefDetail({ view, width, rows }: BriefDetailProps): React.JSX.Element {
  if (view === undefined) {
    return (
      <Box flexDirection="column" width={width}>
        <Text bold>DETAIL</Text>
        <Text dimColor>  no brief selected</Text>
      </Box>
    );
  }

  const { brief, parsed, nextAction } = view;
  const confidenceColour = nextAction.confidence === 'derived' ? 'green' : nextAction.confidence === 'observed' ? 'yellow' : 'gray';

  // The phase table and the judgments both grow with the brief — #0003 has five phases and
  // six findings — so the pane divides what is left rather than running off the bottom.
  const budget = Math.max(4, rows - CHROME_ROWS);
  const phaseBudget = Math.max(2, Math.min(view.phases.length, Math.ceil(budget / 2)));
  const findingBudget = Math.max(2, budget - phaseBudget);
  const phases = view.phases.slice(0, phaseBudget);
  const phasesHidden = view.phases.length - phases.length;
  const defects = view.defects.slice(0, findingBudget);
  const lints = view.lints.slice(0, Math.max(0, findingBudget - defects.length));
  const findingsHidden = view.defects.length - defects.length + (view.lints.length - lints.length);

  return (
    <Box flexDirection="column" width={width} overflow="hidden">
      <Text wrap="truncate-end">
        <Text bold>DETAIL  </Text>
        <Text color="blue" bold>{`#${brief.serial}`}</Text>
        <Text bold>{` ${brief.title}`}</Text>
      </Text>
      <Text wrap="truncate-end">
        <Text dimColor>{'state    '}</Text>
        <Text color={stateColour(parsed.state)}>{parsed.state ?? parsed.raw}</Text>
        {parsed.pointer !== '' ? <Text dimColor>{` ${parsed.pointer}`}</Text> : null}
        {parsed.offVocabulary !== undefined ? <Text color="magenta">{`  ← ${parsed.offVocabulary}`}</Text> : null}
      </Text>
      <Row label="assignee" value={`${brief.assignee}${brief.mine ? '  (mine)' : ''}`} />
      <Row label="owner" value={brief.owner !== '' ? brief.owner : '—, so assignee is the Author'} />
      <Row label="created" value={shortDate(brief.created)} />
      <Row label="closed" value={brief.closed !== '' ? brief.closed : '—'} />
      <Row label="touched" value={brief.touched !== '' ? shortDate(brief.touched) : '—'} />
      <Row label="dir" value={brief.dir} />
      <Box height={1} />
      <Text>
        <Text bold>NEXT  </Text>
        <Text color={confidenceColour}>{`[${nextAction.confidence}]`}</Text>
      </Text>
      <Text wrap="truncate-end">{`  ${nextAction.text !== '' ? nextAction.text : 'nothing owed'}`}</Text>
      <Text dimColor wrap="truncate-end">{`  basis: ${nextAction.basis}`}</Text>
      <Box height={1} />
      <Text bold>{`PHASES  ${view.phases.length}`}</Text>
      {view.phases.length === 0 ? <Text dimColor>  the status line names no phases</Text> : null}
      {phases.map((phase) => (
        <Text key={phase.id} wrap="truncate-end">
          <Text dimColor>{'  '}</Text>
          <Text bold>{phase.id.padEnd(3)}</Text>
          <Text color={stateColour(phase.parsed.state)}>{(phase.parsed.state ?? phase.parsed.raw).padEnd(12)}</Text>
          <Text color={phase.parsed.pointerTruncated ? 'magenta' : 'gray'}>
            {(phase.parsed.pointerTruncated ? 'pointer lost' : phase.pointer !== '' ? phase.pointer : '—').padEnd(14).slice(0, 14)}
          </Text>
          <Text>{phase.label !== '' ? phase.label : ''}</Text>
          {phase.label === '' ? <Text color="magenta">no table row</Text> : null}
        </Text>
      ))}
      {phasesHidden > 0 ? <Text dimColor>{`  … ${phasesHidden} more phases`}</Text> : null}
      <Box height={1} />
      <Text>
        <Text bold>{`DEFECTS  ${view.defects.length}  `}</Text>
        <Text dimColor>the gate&apos;s own output</Text>
      </Text>
      {view.defects.length === 0 ? <Text dimColor>  none</Text> : null}
      {defects.map((defect, i) => (
        <Text key={`${defect.clause}-${i}`} wrap="truncate-end">
          <Text color="red">{`  ${defect.clause} `}</Text>
          <Text dimColor>{`[${defect.kind}] `}</Text>
          <Text>{defect.message}</Text>
        </Text>
      ))}
      {lints.length > 0 ? (
        <>
          <Text>
            <Text bold>{`LINTS  ${view.lints.length}  `}</Text>
            <Text dimColor>found by this console, not by the gate</Text>
          </Text>
          {lints.map((lintItem, i) => (
            <Text key={`${lintItem.clause}-${i}`} wrap="truncate-end">
              <Text color="magenta">{`  ${lintItem.clause} `}</Text>
              <Text>{lintItem.message}</Text>
            </Text>
          ))}
        </>
      ) : null}
      {findingsHidden > 0 ? <Text dimColor>{`  … ${findingsHidden} more findings`}</Text> : null}
      <Box height={1} />
      <Text dimColor wrap="truncate-end">{`  ${brief.status_line !== '' ? brief.status_line : 'no status line'}`}</Text>
    </Box>
  );
}
