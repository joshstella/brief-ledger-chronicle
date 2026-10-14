import { test } from 'node:test';
import assert from 'node:assert/strict';
import { initialState, reducer } from './state.js';
import type { ConsoleState } from './state.js';
import { fromPeerEvent } from '../feed/types.js';
import type { PeerEvent } from '../read-surface/generated/read-surface.js';

function peerEvent(sha: string): PeerEvent {
  return { sha, who: 'dana@example.test', mine: false, synthetic: true, kind: 'phase', serial: '0024', phase: 'b', subject: 'split the renderer' };
}

function withFeed(count: number): ConsoleState {
  let state = initialState;
  for (let i = 0; i < count; i += 1) {
    state = reducer(state, { type: 'feed', entries: [fromPeerEvent(peerEvent(`sha${i}`), new Date(), i)], violations: [] });
  }
  return state;
}

test('a paused feed holds lines and releases them in order', () => {
  let state = reducer(withFeed(1), { type: 'toggle-pause' });
  state = reducer(state, { type: 'feed', entries: [fromPeerEvent(peerEvent('held'), new Date(), 99)], violations: [] });
  assert.equal(state.feed.length, 1);
  assert.equal(state.heldWhilePaused.length, 1);

  state = reducer(state, { type: 'toggle-pause' });
  assert.equal(state.heldWhilePaused.length, 0);
  assert.equal(state.feed.length, 2);
  assert.equal(state.feed[0]?.sha, 'held');
});

test('counters keep counting while the feed is paused', () => {
  // Pausing must not make the record look quiet. The counter is the part a glance reads.
  let state = reducer(initialState, { type: 'toggle-pause' });
  state = reducer(state, { type: 'feed', entries: [fromPeerEvent(peerEvent('x'), new Date(), 1)], violations: [] });
  assert.equal(state.arrivedSinceOpen, 1);
  assert.equal(state.arrivedNotMine, 1);
  assert.equal(state.syntheticSeen, 1);
});

test('selection clamps to the visible count', () => {
  const state = reducer(initialState, { type: 'move', delta: 50, visibleCount: 3 });
  assert.equal(state.selected, 2);
  assert.equal(reducer(state, { type: 'move', delta: -50, visibleCount: 3 }).selected, 0);
});

test('an empty list cannot select a row', () => {
  assert.equal(reducer(initialState, { type: 'move', delta: 1, visibleCount: 0 }).selected, 0);
});

test('cycling the filter returns to where it started and resets the cursor', () => {
  let state = reducer(initialState, { type: 'move', delta: 2, visibleCount: 9 });
  assert.equal(state.selected, 2);
  state = reducer(state, { type: 'cycle-filter' });
  assert.equal(state.filter, 'in-flight');
  assert.equal(state.selected, 0);
  state = reducer(reducer(reducer(state, { type: 'cycle-filter' }), { type: 'cycle-filter' }), { type: 'cycle-filter' });
  assert.equal(state.filter, initialState.filter);
});
