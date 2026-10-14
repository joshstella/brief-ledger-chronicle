import type { ReadSurfaceClient } from '../read-surface/client.js';
import type { RecordEvent, Snapshot } from '../read-surface/generated/read-surface.js';
import type { SchemaViolation } from '../read-surface/validate.js';

export interface RecordPollHandlers {
  /** Events whose sha this poller had not seen before. Newest first, as read.sh gives them. */
  readonly onNewEvents: (events: readonly RecordEvent[], violations: readonly SchemaViolation[]) => void;
  readonly onSnapshot: (snapshot: Snapshot, violations: readonly SchemaViolation[], elapsedMs: number) => void;
  readonly onError: (message: string) => void;
}

export interface RecordPollOptions {
  /** How often to re-read `events`. Cheap: ~0.3 s per call on this fixture. */
  readonly eventIntervalMs: number;
  /**
   * How often to re-read `snapshot`. Expensive: ~3.2 s, of which validate-briefs.sh is ~1 s
   * and the per-brief git log is the rest. Polling it at the event interval would keep a
   * core busy all day for a record that changes a few times an hour.
   */
  readonly snapshotIntervalMs: number;
}

export interface RecordPoll {
  /** Force a snapshot re-read now, for the keyboard refresh. */
  refresh(): void;
  stop(): void;
}

/**
 * Poll the instrument. Two cadences, because the instrument's two answers cost two orders of
 * magnitude apart, and one interval would either miss events or burn a core.
 */
export function startRecordPoll(
  client: ReadSurfaceClient,
  options: RecordPollOptions,
  handlers: RecordPollHandlers,
): RecordPoll {
  const seen = new Set<string>();
  let stopped = false;
  let snapshotInFlight = false;

  const pollEvents = async (first: boolean): Promise<void> => {
    try {
      const { value, violations } = await client.events();
      const fresh = value.filter((e) => !seen.has(e.sha));
      for (const event of value) seen.add(event.sha);
      // The first read seeds the seen-set. Announcing forty commits from three years ago as
      // "new" on open would train the reader to ignore the feed by the second minute.
      if (!first && fresh.length > 0) handlers.onNewEvents(fresh, violations);
    } catch (cause) {
      handlers.onError(cause instanceof Error ? cause.message : String(cause));
    }
  };

  const pollSnapshot = async (): Promise<void> => {
    if (snapshotInFlight) return;
    snapshotInFlight = true;
    try {
      const { value, violations, elapsedMs } = await client.snapshot();
      handlers.onSnapshot(value, violations, elapsedMs);
    } catch (cause) {
      handlers.onError(cause instanceof Error ? cause.message : String(cause));
    } finally {
      snapshotInFlight = false;
    }
  };

  void pollEvents(true);
  void pollSnapshot();

  const eventTimer = setInterval(() => { if (!stopped) void pollEvents(false); }, options.eventIntervalMs);
  const snapshotTimer = setInterval(() => { if (!stopped) void pollSnapshot(); }, options.snapshotIntervalMs);
  eventTimer.unref?.();
  snapshotTimer.unref?.();

  return {
    refresh: () => { void pollSnapshot(); void pollEvents(false); },
    stop: () => {
      stopped = true;
      clearInterval(eventTimer);
      clearInterval(snapshotTimer);
    },
  };
}