import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import type { Identity, RecordEvent, Snapshot } from './generated/read-surface.js';
import { validateAgainst } from './validate.js';
import type { SchemaViolation } from './validate.js';

const run = promisify(execFile);

export interface ReadSurfaceClientOptions {
  /** Absolute path of experiments/blic/read.sh. */
  readonly scriptPath: string;
  /** Directory to run it in. It finds the repository root itself. */
  readonly cwd: string;
  readonly timeoutMs: number;
}

/** One answer from the instrument, with whatever it disagreed with the schema about. */
export interface ReadResult<T> {
  readonly value: T;
  readonly violations: readonly SchemaViolation[];
  /** Wall time of the shell-out, in milliseconds. Reported because it bounds the poll interval. */
  readonly elapsedMs: number;
}

export interface ReadSurfaceClient {
  snapshot(): Promise<ReadResult<Snapshot>>;
  events(since?: string): Promise<ReadResult<readonly RecordEvent[]>>;
  me(): Promise<ReadResult<Identity>>;
}

export class ReadSurfaceError extends Error {
  public constructor(
    public readonly command: readonly string[],
    public override readonly cause: unknown,
  ) {
    super(`read.sh ${command.join(' ')} failed: ${cause instanceof Error ? cause.message : String(cause)}`);
    this.name = 'ReadSurfaceError';
  }
}

export function createReadSurfaceClient(options: ReadSurfaceClientOptions): ReadSurfaceClient {
  async function call(args: readonly string[]): Promise<{ readonly json: unknown; readonly elapsedMs: number }> {
    const started = Date.now();
    try {
      // maxBuffer is raised because `snapshot` over 39 briefs is already 35 kB and the
      // default 1 MB is a cliff a growing record would walk off without warning.
      const { stdout } = await run(options.scriptPath, [...args], {
        cwd: options.cwd,
        timeout: options.timeoutMs,
        maxBuffer: 32 * 1024 * 1024,
      });
      return { json: JSON.parse(stdout) as unknown, elapsedMs: Date.now() - started };
    } catch (cause) {
      throw new ReadSurfaceError(['read.sh', ...args], cause);
    }
  }

  return {
    async snapshot(): Promise<ReadResult<Snapshot>> {
      const { json, elapsedMs } = await call(['snapshot']);
      const { value, violations } = validateAgainst<Snapshot>('Snapshot', json);
      return { value, violations, elapsedMs };
    },

    async events(since?: string): Promise<ReadResult<readonly RecordEvent[]>> {
      // `read.sh snapshot <rev>` accepts a revision and drops it: the dispatcher shifts and
      // then reads $2, so the argument never reaches cmd_events. `events --since` works, so
      // incremental polling goes through the subcommand and pays a second process instead.
      const { json, elapsedMs } = await call(since === undefined ? ['events'] : ['events', '--since', since]);
      const violations: SchemaViolation[] = [];
      const items = Array.isArray(json) ? json : [];
      if (!Array.isArray(json)) violations.push({ path: '', message: 'expected array of events' });
      for (const [i, item] of items.entries()) {
        violations.push(...validateAgainst<RecordEvent>('RecordEvent', item).violations.map((v) => ({
          path: v.path === '' ? String(i) : `${i}/${v.path}`,
          message: v.message,
        })));
      }
      return { value: items as readonly RecordEvent[], violations, elapsedMs };
    },

    async me(): Promise<ReadResult<Identity>> {
      const { json, elapsedMs } = await call(['me']);
      const { value, violations } = validateAgainst<Identity>('Identity', json);
      return { value, violations, elapsedMs };
    },
  };
}
