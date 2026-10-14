import { test } from 'node:test';
import assert from 'node:assert/strict';
import type { Brief, Defect, Phase } from '../read-surface/generated/read-surface.js';
import { buildBriefView } from './brief-view.js';

function phase(id: string, state: string, pointer = '', label = 'a label'): Phase {
  return { id, label, state, pointer };
}

function brief(overrides: Partial<Brief>): Brief {
  return {
    serial: '0039',
    slug: '0039-blic-console',
    dir: 'docs/blc/briefs/0039-blic-console',
    title: 'The record nobody is watching while it changes',
    state: 'in-progress',
    status_line: 'blc/2 #0039 in-progress a:in-progress(blic/bake-off) b:pending',
    owner: '',
    author: 'josh.stella@gmail.com',
    assignee: 'josh.stella@gmail.com',
    mine: true,
    created: '2026-10-14T04:47:41Z',
    closed: '',
    touched: '2026-10-14T00:52:18-04:00',
    has_ledger: true,
    phases: [],
    ...overrides,
  };
}

test('a phase in flight names the branch and the skill', () => {
  const view = buildBriefView(brief({ phases: [phase('a', 'in-progress', 'blic/bake-off'), phase('b', 'pending')] }), []);
  assert.equal(view.nextAction.confidence, 'derived');
  assert.match(view.nextAction.text, /finish phase a on blic\/bake-off/);
  assert.equal(view.inFlight, true);
});

test('a phase in flight that names no branch drops to observed', () => {
  // in-progress is required to carry its branch. When it does not, the console says less
  // rather than inventing a pointer, and the confidence field is where that shows.
  const view = buildBriefView(brief({ phases: [phase('a', 'in-progress')] }), []);
  assert.equal(view.nextAction.confidence, 'observed');
});

test('done with no Closed date derives the close', () => {
  const view = buildBriefView(
    brief({ state: 'done(PR#11)', phases: [phase('1', 'done', 'PR#11')], closed: '' }),
    [],
  );
  assert.equal(view.nextAction.basis, 'BRIEFS-11');
  assert.match(view.nextAction.text, /blc-close-brief/);
  assert.equal(view.open, false);
});

test('done and closed owes nothing', () => {
  const view = buildBriefView(
    brief({ state: 'done', closed: '2026-10-01', phases: [phase('a', 'done', 'PR#44')] }),
    [],
  );
  assert.equal(view.nextAction.confidence, 'none');
  assert.equal(view.nextAction.text, '');
});

test('a filed serial with no ledger is reported, not skipped', () => {
  const view = buildBriefView(brief({ has_ledger: false, state: 'planned', status_line: '' }), []);
  assert.match(view.nextAction.text, /blc-start-brief/);
  assert.equal(view.nextAction.confidence, 'derived');
});

test('a phase missing from the table is a BRIEFS-9 lint', () => {
  const view = buildBriefView(brief({ phases: [phase('1', 'done', 'PR#9', '')] }), []);
  assert.ok(view.lints.some((l) => l.clause === 'BRIEFS-9'));
});

test('gate judgments are matched to the brief by slug and not re-derived', () => {
  const defect: Defect = {
    clause: 'BRIEFS-11',
    kind: 'judgment',
    subject: '0039-blic-console',
    message: 'status line says done, and ledger.md records no **Closed:** date',
  };
  const other: Defect = { ...defect, subject: '0001-bootstrap' };
  const view = buildBriefView(brief({}), [defect, other]);
  assert.deepEqual(view.defects, [defect]);
});
