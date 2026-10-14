#!/usr/bin/env node
import { render } from 'ink';
import { ConfigError, loadConfig, parseArgs } from './config.js';
import type { ConsoleConfig } from './config.js';
import { App } from './ui/App.js';

function main(): void {
  let config: ConsoleConfig;
  try {
    config = loadConfig(parseArgs(process.argv.slice(2)));
  } catch (error) {
    if (error instanceof ConfigError) {
      process.stderr.write(`${error.message}\n`);
      process.exit(error.message.startsWith('blic-p3') ? 0 : 2);
    }
    throw error;
  }

  const instance = render(<App config={config} />, {
    // Ctrl-C is handled in the app so the peer stream and the pollers are stopped first. A
    // console that leaves peer-events.sh running after it exits is a console you stop trusting.
    exitOnCtrlC: false,
    patchConsole: false,
  });

  void instance.waitUntilExit().then(() => { process.exit(0); });
}

main();
