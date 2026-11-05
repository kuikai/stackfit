import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  addFinishedTabata,
  classicTabata,
  nextTabataStep,
  setupError,
  tabataNextLabel,
  tabataTotalSeconds,
} from '../../website/js/tabata_rules.js';

function firstRound(setup) {
  return { ...setup, phase: 'work', roundIndex: 0, remaining: setup.work };
}

test('classic Tabata lasts 3:50 because the last rest is skipped', () => {
  assert.equal(tabataTotalSeconds(classicTabata), 8 * 20 + 7 * 10);
});

test('rounds alternate work and rest, and end without a final rest', () => {
  let step = firstRound({ work: 20, rest: 10, rounds: 2 });
  assert.equal(tabataNextLabel(step), 'Then 10s rest');
  step = nextTabataStep(step);
  assert.deepEqual([step.phase, step.roundIndex, step.remaining], ['rest', 0, 10]);
  assert.equal(tabataNextLabel(step), 'Next: round 2 of 2');
  step = nextTabataStep(step);
  assert.deepEqual([step.phase, step.roundIndex, step.remaining], ['work', 1, 20]);
  assert.equal(tabataNextLabel(step), 'Last round');
  assert.equal(nextTabataStep(step).phase, 'done');
});

test('zero rest goes straight to the next round', () => {
  const step = firstRound({ work: 30, rest: 0, rounds: 3 });
  assert.equal(tabataNextLabel(step), 'Next round straight after');
  assert.deepEqual([nextTabataStep(step).phase, nextTabataStep(step).roundIndex], ['work', 1]);
});

test('the setup form rejects out-of-range numbers', () => {
  assert.equal(setupError(classicTabata), '');
  assert.match(setupError({ ...classicTabata, work: 0 }), /Work time/);
  assert.match(setupError({ ...classicTabata, rest: 601 }), /Rest time/);
  assert.match(setupError({ ...classicTabata, rounds: 1.5 }), /Rounds/);
});

test('a finished Tabata is saved as a timer workout and one session', () => {
  const snapshot = { workouts: [], sessions: [] };
  addFinishedTabata(snapshot, { name: 'Tabata', work: 20, rest: 10, rounds: 8, elapsed: 230 });
  const [workout] = snapshot.workouts;
  const [session] = snapshot.sessions;
  assert.deepEqual(workout.exercises.map((exercise) => [exercise.type, exercise.workSeconds, exercise.restSeconds, exercise.sets]), [['timer', 20, 10, 8]]);
  assert.equal(session.workoutId, workout.id);
  assert.equal(session.durationSeconds, 230);
});
