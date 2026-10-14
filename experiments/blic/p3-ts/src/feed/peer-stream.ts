import { spawn } from 'node:child_process';
import type { ChildProcessWithoutNullStreams } from 'node:child_process';
import { createInterface } from 'node:readline';
import type { PeerEvent } from '../read-surface/generated/read-surface.js';
import { validateAgainst } from '../read-surface/validate.js';
import type { SchemaViolation } from '../read-surface/validate.js';

export interface PeerStreamOptions {
  /** Absolute path of experiments/blic/peer-events.sh. */
  readonly scriptPath: string;
  readonly cwd: string;
  /** Seconds between lines. Passed as BLIC_PEER_INTERVAL, which the generator reads. */
  readonly intervalSeconds: number;
}

export interface PeerStreamHandlers {
  readonly onEvent: (event: PeerEvent, violations: readonly SchemaViolation[]) => void;
  readonly onError: (message: string) => void;
  readonly onExit: (code: number | null) => void;
}

export interface PeerStream {
  stop(): void;
}

/**
 * Follow peer-events.sh --stream line by line. Each line is checked against the PeerEvent
 * definition before it is handed on, so a line that lost its `synthetic` field is reported as
 * a violation instead of being rendered as if it were real.
 */
export function startPeerStream(options: PeerStreamOptions, handlers: PeerStreamHandlers): PeerStream {
  let child: ChildProcessWithoutNullStreams | undefined;
  try {
    child = spawn(options.scriptPath, ['--stream'], {
      cwd: options.cwd,
      env: { ...process.env, BLIC_PEER_INTERVAL: String(options.intervalSeconds) },
    }) as ChildProcessWithoutNullStreams;
  } catch (cause) {
    handlers.onError(`peer-events.sh could not start: ${cause instanceof Error ? cause.message : String(cause)}`);
    return { stop: () => undefined };
  }

  const lines = createInterface({ input: child.stdout });
  lines.on('line', (line: string) => {
    const text = line.trim();
    if (text === '') return;
    let parsed: unknown;
    try {
      parsed = JSON.parse(text) as unknown;
    } catch {
      handlers.onError(`peer-events.sh printed a line that is not JSON: ${text.slice(0, 60)}`);
      return;
    }
    const { value, violations } = validateAgainst<PeerEvent>('PeerEvent', parsed);
    handlers.onEvent(value, violations);
  });

  child.stderr.on('data', (chunk: Buffer) => { handlers.onError(chunk.toString().trim()); });
  child.on('error', (error: Error) => { handlers.onError(error.message); });
  child.on('exit', (code: number | null) => { handlers.onExit(code); });

  return {
    stop: () => {
      lines.close();
      child?.kill('SIGTERM');
    },
  };
}
