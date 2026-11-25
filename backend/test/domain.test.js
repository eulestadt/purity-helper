const test = require('node:test');
const assert = require('node:assert/strict');
const { derive, projectPublic, streakAsOf } = require('../src/domain');

const today = '2026-11-24';

function event(key, value) {
  return { key, value, deleted: false };
}

test('streak counts civil days from samples, not a stored counter', () => {
  assert.equal(streakAsOf([], today, '2026-11-20'), 5);
  assert.equal(streakAsOf(['2026-11-24'], today, '2026-11-20'), 0);
  assert.equal(streakAsOf(['2026-11-22'], today, '2026-11-01'), 2);
  assert.equal(streakAsOf(['2026-11-22'], '2026-11-23', '2026-11-01'), 1);
  assert.equal(streakAsOf([], today, null), 0);
  assert.equal(streakAsOf(['2026-12-01'], today, '2026-11-01'), 24);
});

test('a full spiritual day closes four rings without touching the clear streak', () => {
  const docs = [
    event('profile', { journeyStart: '2026-11-24', hoursPerDay: 2, mission: 'See God' }),
    event('event/urge-1', { kind: 'urge', day: today, at: '2026-11-24T22:00:00Z', outcome: 'surfed', hour: 22, weekday: 2 }),
    event('event/prayer-1', { kind: 'prayer', day: today, at: '2026-11-24T11:00:00Z', form: 'intention' }),
    event('event/examen-1', { kind: 'examen', day: today, at: '2026-11-24T23:00:00Z', how: 'tired', resolve: 'phone stays downstairs' }),
    event('event/word-1', { kind: 'scripture', day: today, at: '2026-11-24T12:00:00Z' }),
    event('event/verse-1', { kind: 'verse', day: today, at: '2026-11-24T12:10:00Z' }),
  ];
  const derived = derive(docs, { today });
  assert.deepEqual(derived.rings, { clear: 1, watch: 1, prayer: 1, word: 1 });
  assert.equal(derived.fullDay, true);
  assert.equal(derived.streaks.clear, 1);
  assert.equal(derived.hoursReclaimed, 2);
  assert.equal(derived.tree.id, 'seedling');
  assert.equal(derived.danger.busiestHour, 22);
});

test('a body relapse empties the clear ring and the streak, and a thought relapse empties watch', () => {
  const docs = [
    event('profile', { journeyStart: '2026-11-01' }),
    event('event/relapse-body', { kind: 'relapse', day: today, at: '2026-11-24T03:00:00Z', type: 'pornography', hour: 3, weekday: 2 }),
    event('event/relapse-mind', { kind: 'relapse', day: today, at: '2026-11-24T03:05:00Z', type: 'thought' }),
    event('event/urge', { kind: 'urge', day: today, at: '2026-11-24T03:01:00Z', outcome: 'surfed' }),
  ];
  const derived = derive(docs, { today });
  assert.equal(derived.rings.clear, 0);
  assert.equal(derived.rings.watch, 0);
  assert.equal(derived.streaks.clear, 0);
  assert.equal(derived.streaks.pornography, 0);
  assert.equal(derived.streaks.masturbation, 24);
});

test('share projection hides journals unless the person opts in', () => {
  const docs = [
    event('profile', { journeyStart: today, mission: 'Hidden', shareMission: false, shareRelapses: false }),
    event('event/relapse', { kind: 'relapse', day: today, at: '2026-11-24T01:00:00Z', type: 'masturbation', note: 'private' }),
  ];
  const summary = projectPublic(derive(docs, { today }));
  assert.equal(summary.mission, undefined);
  assert.equal(summary.relapses, undefined);
  assert.equal(summary.rings.clear, 0);
  assert.ok(summary.streaks);

  docs[0].value.shareRelapses = true;
  docs[0].value.shareMission = true;
  const open = projectPublic(derive(docs, { today }));
  assert.equal(open.mission, 'Hidden');
  assert.equal(open.relapses.length, 1);
  assert.equal(open.relapses[0].note, 'private');
});
