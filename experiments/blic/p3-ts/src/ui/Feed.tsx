import React from 'react';
import { Box, Text } from 'ink';
import type { FeedEntry } from '../feed/types.js';
import { KIND_COLOUR, kindTag, shortTime } from './theme.js';

export interface FeedProps {
  readonly entries: readonly FeedEntry[];
  readonly paused: boolean;
  readonly heldCount: number;
  readonly focused: boolean;
  readonly rows: number;
  readonly width: number;
}

/**
 * One feed line. The synthetic marker is rendered from the provenance union, so a line can
 * only reach the screen unmarked if this branch is deleted — which is the point of making
 * provenance a union rather than an optional flag.
 */
function FeedLine({ entry, width }: { readonly entry: FeedEntry; readonly width: number }): React.JSX.Element {
  const synthetic = entry.provenance.source === 'synthetic';
  const ref = entry.serial !== '' ? `#${entry.serial}${entry.phase}` : entry.sha;
  return (
    <Text wrap="truncate-end">
      <Text dimColor>{shortTime(entry.when)}</Text>
      <Text dimColor>{entry.whenIsArrival ? '~' : ' '}</Text>
      {synthetic ? <Text backgroundColor="magenta" color="black" bold> SYNTHETIC </Text> : <Text dimColor>{'  record   '}</Text>}
      <Text color={KIND_COLOUR[entry.kind]}>{` ${kindTag(entry.kind)}`}</Text>
      <Text color={entry.mine ? 'gray' : 'yellow'} bold={!entry.mine}>{entry.mine ? ' me    ' : ' THEIRS'}</Text>
      <Text color="blue">{` ${ref.padEnd(9).slice(0, 9)}`}</Text>
      <Text>{` ${entry.subject.slice(0, Math.max(10, width - 48))}`}</Text>
    </Text>
  );
}

export function Feed({ entries, paused, heldCount, focused, rows, width }: FeedProps): React.JSX.Element {
  return (
    <Box flexDirection="column" width={width}>
      <Text>
        <Text bold color={focused ? 'cyan' : 'white'}>{focused ? '▌' : ' '}FEED</Text>
        <Text dimColor>{`  newest first  ${entries.length}`}</Text>
        {paused ? <Text backgroundColor="yellow" color="black" bold>{` PAUSED, ${heldCount} held `}</Text> : null}
      </Text>
      {entries.length === 0 ? <Text dimColor>  waiting for the record to change…</Text> : null}
      {entries.slice(0, rows).map((entry) => (
        <FeedLine key={entry.key} entry={entry} width={width} />
      ))}
    </Box>
  );
}
