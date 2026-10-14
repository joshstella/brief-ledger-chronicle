import { execFileSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';
import { FILTER_ORDER } from './ui/state.js';
import type { BriefFilter } from './ui/state.js';

export interface ConsoleConfig {
  readonly repoRoot: string;
  readonly readScript: string;
  readonly peerScript: string;
  readonly eventIntervalMs: number;
  readonly snapshotIntervalMs: number;
  readonly peersEnabled: boolean;
  readonly peerIntervalSeconds: number;
  /** When set, run without keyboard input and exit after this many seconds. For captures. */
  readonly captureSeconds: number | undefined;
  /**
   * Starting filter and cursor row. These exist for captures: a capture has no TTY, so raw
   * mode is unavailable and no keystroke can be recorded. A flag renders the same screen the
   * key would, and it is honest about which it was.
   */
  readonly filter: BriefFilter;
  readonly select: number;
}

export interface CliArgs {
  readonly eventIntervalMs?: number;
  readonly snapshotIntervalMs?: number;
  readonly peersEnabled?: boolean;
  readonly peerIntervalSeconds?: number;
  readonly captureSeconds?: number;
  readonly filter?: BriefFilter;
  readonly select?: number;
}

export class ConfigError extends Error {}

function repoRoot(): string {
  // The instrument finds the repository root itself; this console needs it only to locate the
  // two scripts, which sit beside it at experiments/blic/.
  const root = execFileSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8' }).trim();
  if (root === '') throw new ConfigError('not inside a git repository');
  return root;
}

export function parseArgs(argv: readonly string[]): CliArgs {
  const args: {
    eventIntervalMs?: number;
    snapshotIntervalMs?: number;
    peersEnabled?: boolean;
    peerIntervalSeconds?: number;
    captureSeconds?: number;
    filter?: BriefFilter;
    select?: number;
  } = {};
  for (const arg of argv) {
    const [flag, raw] = arg.split('=', 2);
    const value = raw === undefined ? undefined : Number(raw);
    switch (flag) {
      case '--no-peers': args.peersEnabled = false; break;
      case '--peers': args.peersEnabled = true; break;
      case '--peer-interval': if (value !== undefined) args.peerIntervalSeconds = value; break;
      case '--event-interval': if (value !== undefined) args.eventIntervalMs = value * 1000; break;
      case '--snapshot-interval': if (value !== undefined) args.snapshotIntervalMs = value * 1000; break;
      case '--capture': args.captureSeconds = value ?? 30; break;
      case '--select': if (value !== undefined) args.select = value; break;
      case '--filter': {
        if (raw === undefined) break;
        if (!(FILTER_ORDER as readonly string[]).includes(raw)) {
          throw new ConfigError(`unknown filter: ${raw} (one of ${FILTER_ORDER.join(', ')})`);
        }
        args.filter = raw as BriefFilter;
        break;
      }
      case '--help':
      case '-h':
        throw new ConfigError(
          [
            'blic-p3 — a read-only BLC console (bake-off prototype 3)',
            '',
            '  --no-peers              do not start peer-events.sh',
            '  --peer-interval=N       seconds between synthetic events (default 7)',
            '  --event-interval=N      seconds between read.sh events polls (default 5)',
            '  --snapshot-interval=N   seconds between read.sh snapshot reads (default 60)',
            '  --capture=N             render without keyboard input, exit after N seconds',
            `  --filter=F              start on a filter: ${FILTER_ORDER.join(', ')}`,
            '  --select=N              start with row N selected',
          ].join('\n'),
        );
      default:
        if (flag !== undefined && flag.startsWith('-')) throw new ConfigError(`unknown flag: ${flag}`);
    }
  }
  return args;
}

export function loadConfig(args: CliArgs): ConsoleConfig {
  const root = repoRoot();
  const readScript = join(root, 'experiments', 'blic', 'read.sh');
  const peerScript = join(root, 'experiments', 'blic', 'peer-events.sh');
  if (!existsSync(readScript)) throw new ConfigError(`the read surface is missing: ${readScript}`);
  if (!existsSync(peerScript)) throw new ConfigError(`the peer generator is missing: ${peerScript}`);

  return {
    repoRoot: root,
    readScript,
    peerScript,
    // `events` costs ~0.3 s and `snapshot` ~3.2 s on this fixture, so they are polled apart.
    eventIntervalMs: args.eventIntervalMs ?? 5_000,
    snapshotIntervalMs: args.snapshotIntervalMs ?? 60_000,
    peersEnabled: args.peersEnabled ?? true,
    peerIntervalSeconds: args.peerIntervalSeconds ?? 7,
    captureSeconds: args.captureSeconds,
    filter: args.filter ?? 'mine-open',
    select: args.select ?? 0,
  };
}
