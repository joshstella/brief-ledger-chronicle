import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseState } from './state.js';

// Every string asserted here was taken from a live `read.sh briefs` run over the 39 briefs in
// this repository, not invented. The fixture is the point of the bake-off.

test('a bare state is in the vocabulary', () => {
  const parsed = parseState('in-progress');
  assert.equal(parsed.state, 'in-progress');
  assert.equal(parsed.pointer, '');
  assert.equal(parsed.offVocabulary, undefined);
});

test('the brief-level pointer comes off the state', () => {
  const parsed = parseState('done(PR#11)');
  assert.equal(parsed.state, 'done');
  assert.equal(parsed.pointer, 'PR#11');
  assert.equal(parsed.offVocabulary, undefined);
});

test('a pointer with a space still yields a state', () => {
  const parsed = parseState('done(commit 92a7168)');
  assert.equal(parsed.state, 'done');
  assert.equal(parsed.pointer, 'commit 92a7168');
});

test('the tokenizer-truncated phase token is reported, not guessed at', () => {
  // read.sh splits phase entries on whitespace, so `1:done(commit 92a7168)` reaches a
  // consumer as the state `done(commit` with no closing paren. It parses to `done` and the
  // lost pointer stays lost rather than being reconstructed from nothing.
  const parsed = parseState('done(commit');
  assert.equal(parsed.state, 'done');
  assert.equal(parsed.pointer, '');
  assert.equal(parsed.pointerTruncated, true);
});

test('no-line is named as off-vocabulary', () => {
  const parsed = parseState('no-line');
  assert.equal(parsed.state, undefined);
  assert.match(parsed.offVocabulary ?? '', /no status line/);
});

test('planned is off-vocabulary, because the vocabulary does not have it', () => {
  // tools/list-briefs.sh prints `planned` for a brief with no ledger. The five-state
  // vocabulary in docs/blc/briefs/README.md does not contain it. #0039 cites the
  // disagreement; this is the assertion that keeps the console from hiding it.
  const parsed = parseState('planned');
  assert.equal(parsed.state, undefined);
  assert.match(parsed.offVocabulary ?? '', /not in the five-state vocabulary/);
});
