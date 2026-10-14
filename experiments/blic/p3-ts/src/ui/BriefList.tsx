import React from 'react';
import { Box, Text } from 'ink';
import type { BriefView } from '../model/brief-view.js';
import { stateColour } from './theme.js';

export interface BriefListProps {
  readonly briefs: readonly BriefView[];
  readonly selected: number;
  readonly focused: boolean;
  readonly filterLabel: string;
  /** Rows available for brief lines, excluding the header. */
  readonly rows: number;
  readonly width: number;
}

/** Keep the cursor inside the window without moving it when it does not have to move. */
function windowStart(selected: number, rows: number, total: number): number {
  if (total <= rows) return 0;
  const half = Math.floor(rows / 2);
  return Math.max(0, Math.min(selected - half, total - rows));
}

export function BriefList({ briefs, selected, focused, filterLabel, rows, width }: BriefListProps): React.JSX.Element {
  const start = windowStart(selected, rows, briefs.length);
  const slice = briefs.slice(start, start + rows);

  return (
    <Box flexDirection="column" width={width} overflow="hidden">
      <Text wrap="truncate-end">
        <Text bold color={focused ? 'cyan' : 'white'}>{focused ? '▌' : ' '}BRIEFS</Text>
        <Text dimColor>{`  ${filterLabel}  ${briefs.length}`}</Text>
      </Text>
      {slice.length === 0 ? <Text dimColor>  nothing matches this filter</Text> : null}
      {slice.map((view, i) => {
        const isSelected = start + i === selected;
        const parsed = view.parsed;
        const flags =
          (view.defects.length > 0 ? '!' : ' ') +
          (view.lints.length > 0 ? '~' : ' ') +
          (view.brief.mine ? '@' : ' ');
        return (
          <Text key={view.brief.slug} inverse={isSelected && focused} bold={isSelected} wrap="truncate-end">
            <Text>{isSelected ? '▸' : ' '}</Text>
            <Text color="blue">{` #${view.brief.serial} `}</Text>
            <Text color={stateColour(parsed.state)}>{(parsed.state ?? parsed.raw).padEnd(11).slice(0, 11)}</Text>
            <Text color="yellow">{flags}</Text>
            <Text>{` ${view.brief.title}`}</Text>
          </Text>
        );
      })}
      {briefs.length > rows ? (
        <Text dimColor>{`  … ${start + slice.length}/${briefs.length}`}</Text>
      ) : null}
    </Box>
  );
}
