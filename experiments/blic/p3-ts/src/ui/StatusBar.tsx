import React from 'react';
import { Box, Text } from 'ink';
import type { ConsoleState } from './state.js';
import { shortTime } from './theme.js';

export interface StatusBarProps {
  readonly state: ConsoleState;
  readonly rssMb: number;
  readonly width: number;
}

export function StatusBar({ state, rssMb, width }: StatusBarProps): React.JSX.Element {
  const snapshot = state.snapshot;
  const defects = snapshot?.defects.length ?? 0;
  const declarations = snapshot?.declarations.length ?? 0;
  const lastError = state.errors[0];

  return (
    <Box flexDirection="column" width={width} overflow="hidden">
      <Text wrap="truncate-end">
        <Text dimColor>{'↑↓/jk move  ⇥ pane  f filter  p pause  r refresh  q quit'}</Text>
      </Text>
      <Text wrap="truncate-end">
        <Text color="blue">{snapshot !== undefined ? `${snapshot.branch}@${snapshot.head}` : 'reading…'}</Text>
        <Text dimColor>{'  '}</Text>
        <Text>{snapshot?.me.email ?? ''}</Text>
        <Text dimColor>{'  │ '}</Text>
        <Text color={defects > 0 ? 'red' : 'green'}>{`${defects} gate judgments`}</Text>
        <Text dimColor>{'  '}</Text>
        <Text color={declarations > 0 ? 'yellow' : 'gray'}>{`${declarations} declarations`}</Text>
        <Text dimColor>{'  │ '}</Text>
        <Text color={state.arrivedNotMine > 0 ? 'yellow' : 'gray'} bold={state.arrivedNotMine > 0}>
          {`${state.arrivedNotMine} not mine`}
        </Text>
        <Text dimColor>{` of ${state.arrivedSinceOpen} since open`}</Text>
        {state.syntheticSeen > 0 ? <Text color="magenta">{`  (${state.syntheticSeen} synthetic)`}</Text> : null}
      </Text>
      <Text wrap="truncate-end">
        <Text dimColor>{`read ${state.lastReadMs} ms`}</Text>
        <Text dimColor>{state.lastReadAt !== undefined ? ` at ${shortTime(state.lastReadAt)}` : ''}</Text>
        <Text dimColor>{`  rss ${rssMb.toFixed(0)} MB`}</Text>
        {state.reading ? <Text color="cyan">{'  reading…'}</Text> : null}
        {state.violations.length > 0 ? (
          <Text color="magenta">{`  ${state.violations.length} schema violations: ${state.violations[0]?.path ?? ''} ${state.violations[0]?.message ?? ''}`}</Text>
        ) : null}
        {lastError !== undefined ? <Text color="red">{`  ${lastError.slice(0, 60)}`}</Text> : null}
      </Text>
    </Box>
  );
}
