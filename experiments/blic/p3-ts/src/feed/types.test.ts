import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { PeerEvent, RecordEvent } from '../read-surface/generated/read-surface.js';
import { fromPeerEvent, fromRecordEvent, isSynthetic } from './types.js';
import { validateAgainst } from '../read-surface/validate.js';

const peer: PeerEvent = {
  sha: 'c0ffee01',
  who: 'dana@example.test',
  mine: false,
  synthetic: true,
  kind: 'phase',
  serial: '0024',
  phase: 'b',
  subject: '[#0024b] split the renderer from the scan',
};

const record: RecordEvent = {
  sha: '2df3bf3f',
  when: '2026-10-14T00:52:18-04:00',
  who: 'josh.stella@gmail.com',
  mine: true,
  kind: 'filed',
  serial: '0039',
  phase: '',
  subject: 'docs: file #0039 and open its ledger, the BLIC console',
};

test('a peer event carries its provenance into the feed', () => {
  const entry = fromPeerEvent(peer, new Date('2026-10-14T05:00:00Z'), 1);
  assert.equal(entry.provenance.source, 'synthetic');
  assert.equal(isSynthetic(entry), true);
});

test('a peer event timestamp is marked as arrival, because the generator emits none', () => {
  const entry = fromPeerEvent(peer, new Date('2026-10-14T05:00:00Z'), 1);
  assert.equal(entry.whenIsArrival, true);
  assert.equal(entry.when, '2026-10-14T05:00:00.000Z');
});

test('a record event keeps the commit date', () => {
  const entry = fromRecordEvent(record);
  assert.equal(entry.whenIsArrival, false);
  assert.equal(entry.when, record.when);
  assert.equal(isSynthetic(entry), false);
});

test('repeated peer shas get distinct keys across stream cycles', () => {
  // peer-events.sh --stream loops the same five lines forever, so the sha is not unique in a
  // session and a sha-keyed list would collapse the second cycle into the first.
  const first = fromPeerEvent(peer, new Date(), 1);
  const second = fromPeerEvent(peer, new Date(), 6);
  assert.notEqual(first.key, second.key);
});

test('a peer line that lost its synthetic field is a violation', () => {
  const { synthetic: _dropped, ...stripped } = peer;
  const { violations } = validateAgainst<PeerEvent>('PeerEvent', stripped);
  assert.ok(violations.some((v) => v.path === 'synthetic'));
});

test('the real snapshot validates against the schema the types came from', () => {
  // A smoke check of the generated-types claim: if read.sh adds a field or renames one, this
  // fails before any screen is drawn.
  const { violations } = validateAgainst('RecordEvent', record);
  assert.deepEqual(violations, []);
});
