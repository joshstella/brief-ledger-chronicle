import React, { useEffect, useMemo, useReducer, useRef, useState } from 'react';
import { Box, Text, useApp, useInput } from 'ink';
import type { ConsoleConfig } from '../config.js';
import { createReadSurfaceClient } from '../read-surface/client.js';
import { startRecordPoll } from '../feed/record-poll.js';
import { startPeerStream } from '../feed/peer-stream.js';
import { fromPeerEvent, fromRecordEvent } from '../feed/types.js';
import { FILTER_LABEL, initialState, reducer, visibleBriefs } from './state.js';
import { BriefList } from './BriefList.js';
import { BriefDetail } from './BriefDetail.js';
import { Feed } from './Feed.js';
import { StatusBar } from './StatusBar.js';

export interface AppProps {
  readonly config: ConsoleConfig;
}

export interface TerminalSize {
  readonly columns: number;
  readonly rows: number;
}

/**
 * Terminal size, falling back to $COLUMNS and $LINES. The fallback is not cosmetic: a capture
 * run has no TTY, so `process.stdout.columns` is undefined and the frames in the transcript
 * would be 100 columns wide whatever the terminal that produced them was.
 */
function readSize(): TerminalSize {
  const envColumns = Number(process.env['COLUMNS']);
  const envRows = Number(process.env['LINES']);
  return {
    columns: process.stdout.columns ?? (Number.isFinite(envColumns) && envColumns > 0 ? envColumns : 100),
    rows: process.stdout.rows ?? (Number.isFinite(envRows) && envRows > 0 ? envRows : 30),
  };
}

function useTerminalSize(): TerminalSize {
  const [size, setSize] = useState<TerminalSize>(readSize);
  useEffect(() => {
    const onResize = (): void => { setSize(readSize()); };
    process.stdout.on('resize', onResize);
    return () => { process.stdout.off('resize', onResize); };
  }, []);
  return size;
}

/** Sampled rather than read once: the number the report needs is RSS while running, not at boot. */
function useRssMb(): number {
  const [rss, setRss] = useState<number>(process.memoryUsage.rss() / 1024 / 1024);
  useEffect(() => {
    const timer = setInterval(() => { setRss(process.memoryUsage.rss() / 1024 / 1024); }, 2000);
    timer.unref?.();
    return () => { clearInterval(timer); };
  }, []);
  return rss;
}

export function App({ config }: AppProps): React.JSX.Element {
  const [state, dispatch] = useReducer(reducer, {
    ...initialState,
    filter: config.filter,
    selected: config.select,
  });
  const { columns, rows } = useTerminalSize();
  const rssMb = useRssMb();
  const refreshRef = useRef<(() => void) | undefined>(undefined);
  const { exit } = useApp();

  const client = useMemo(
    () => createReadSurfaceClient({ scriptPath: config.readScript, cwd: config.repoRoot, timeoutMs: 30_000 }),
    [config.readScript, config.repoRoot],
  );

  useEffect(() => {
    const poll = startRecordPoll(
      client,
      { eventIntervalMs: config.eventIntervalMs, snapshotIntervalMs: config.snapshotIntervalMs },
      {
        onNewEvents: (events, violations) => {
          dispatch({ type: 'feed', entries: events.map(fromRecordEvent), violations });
        },
        onSnapshot: (snapshot, violations, elapsedMs) => {
          dispatch({ type: 'snapshot', snapshot, violations, elapsedMs });
        },
        onError: (message) => { dispatch({ type: 'error', message }); },
      },
    );
    refreshRef.current = poll.refresh;
    return () => { poll.stop(); };
  }, [client, config.eventIntervalMs, config.snapshotIntervalMs]);

  useEffect(() => {
    if (!config.peersEnabled) return undefined;
    let sequence = 0;
    const stream = startPeerStream(
      { scriptPath: config.peerScript, cwd: config.repoRoot, intervalSeconds: config.peerIntervalSeconds },
      {
        onEvent: (event, violations) => {
          sequence += 1;
          dispatch({ type: 'feed', entries: [fromPeerEvent(event, new Date(), sequence)], violations });
        },
        onError: (message) => { dispatch({ type: 'error', message: `peer-events.sh: ${message}` }); },
        onExit: (code) => { dispatch({ type: 'error', message: `peer-events.sh exited with ${code ?? 'signal'}` }); },
      },
    );
    return () => { stream.stop(); };
  }, [config.peersEnabled, config.peerScript, config.repoRoot, config.peerIntervalSeconds]);

  const briefs = visibleBriefs(state);

  useInput(
    (input, key) => {
      if (input === 'q' || (key.ctrl && input === 'c')) { exit(); return; }
      if (input === 'j' || key.downArrow) { dispatch({ type: 'move', delta: 1, visibleCount: briefs.length }); return; }
      if (input === 'k' || key.upArrow) { dispatch({ type: 'move', delta: -1, visibleCount: briefs.length }); return; }
      if (key.pageDown) { dispatch({ type: 'move', delta: 10, visibleCount: briefs.length }); return; }
      if (key.pageUp) { dispatch({ type: 'move', delta: -10, visibleCount: briefs.length }); return; }
      if (input === 'g') { dispatch({ type: 'select', index: 0 }); return; }
      if (input === 'G') { dispatch({ type: 'move', delta: briefs.length, visibleCount: briefs.length }); return; }
      if (input === 'f') { dispatch({ type: 'cycle-filter' }); return; }
      if (key.tab) { dispatch({ type: 'cycle-pane' }); return; }
      if (input === 'p') { dispatch({ type: 'toggle-pause' }); return; }
      if (input === 'r') { dispatch({ type: 'reading', reading: true }); refreshRef.current?.(); return; }
    },
    { isActive: config.captureSeconds === undefined },
  );

  useEffect(() => {
    if (config.captureSeconds === undefined) return undefined;
    const timer = setTimeout(() => { exit(); }, config.captureSeconds * 1000);
    return () => { clearTimeout(timer); };
  }, [config.captureSeconds, exit]);

  // Rows are divided rather than flexed: Ink will happily overflow a short terminal, and a
  // console that scrolls its own header off the screen is useless as a thing you glance at.
  const statusRows = 3;
  const feedRows = Math.max(4, Math.min(9, Math.floor((rows - statusRows) * 0.35)));
  const topRows = Math.max(4, rows - statusRows - feedRows - 2);
  const listWidth = Math.max(34, Math.floor(columns * 0.42));
  const detailWidth = Math.max(30, columns - listWidth - 3);

  return (
    <Box flexDirection="column" width={columns}>
      <Box flexDirection="row" height={topRows}>
        <BriefList
          briefs={briefs}
          selected={state.selected}
          focused={state.pane === 'briefs'}
          filterLabel={FILTER_LABEL[state.filter]}
          rows={topRows - 2}
          width={listWidth}
        />
        <Box width={1} />
        <Box flexDirection="column" borderStyle="single" borderTop={false} borderRight={false} borderBottom={false} borderLeft paddingLeft={1}>
          <BriefDetail view={briefs[state.selected]} width={detailWidth} rows={topRows} />
        </Box>
      </Box>
      <Text dimColor>{'─'.repeat(Math.max(1, columns - 1))}</Text>
      <Box height={feedRows}>
        <Feed
          entries={state.feed}
          paused={state.feedPaused}
          heldCount={state.heldWhilePaused.length}
          focused={state.pane === 'feed'}
          rows={feedRows - 1}
          width={columns - 1}
        />
      </Box>
      <Text dimColor>{'─'.repeat(Math.max(1, columns - 1))}</Text>
      <StatusBar state={state} rssMb={rssMb} width={columns - 1} />
    </Box>
  );
}
