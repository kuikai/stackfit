import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  advanceWork,
  blankRun,
  completeSet,
  enterBlock,
  finishRest,
} from '../../website/js/workout_steps.js';

function start(workout) {
  return enterBlock(blankRun(workout), 0);
}

function where(state) {
  return [state.phase, state.blockIndex, state.roundIndex, state.exerciseIndex, state.setIndex, state.remaining];
}

test('sets rest between sets, then move on to the next exercise', () => {
  const workout = {
    exercises: [
      { name: 'Bench press', type: 'sets', sets: 2, reps: 8, restSeconds: 90 },
      { name: 'Dips', type: 'sets', sets: 1, reps: 12, restSeconds: 0 },
    ],
  };
  let state = start(workout);
  assert.deepEqual(where(state), ['set', 0, 0, 0, 0, 0]);
  state = completeSet(state);
  assert.deepEqual(where(state), ['rest', 0, 0, 0, 0, 90]);
  state = finishRest(state);
  assert.deepEqual(where(state), ['set', 0, 0, 0, 1, 0]);
  state = completeSet(state);
  assert.deepEqual(where(state), ['rest', 0, 0, 0, 1, 90]);
  state = finishRest(state);
  assert.deepEqual(where(state), ['set', 1, 0, 0, 0, 0]);
  assert.equal(completeSet(state).phase, 'done');
});

test('a timer exercise rests between rounds but not after the last one', () => {
  const workout = {
    exercises: [{ name: 'Burpees', type: 'timer', workSeconds: 40, restSeconds: 20, sets: 2 }],
  };
  let state = start(workout);
  assert.deepEqual(where(state), ['work', 0, 0, 0, 0, 40]);
  state = advanceWork(state);
  assert.deepEqual(where(state), ['rest', 0, 0, 0, 0, 20]);
  state = finishRest(state);
  assert.deepEqual(where(state), ['work', 0, 0, 0, 1, 40]);
  assert.equal(advanceWork(state).phase, 'done');
});

test('a circuit goes station by station, rests between rounds, then finishes', () => {
  const workout = {
    blocks: [{
      type: 'circuit',
      rounds: 2,
      restBetweenRoundsSeconds: 60,
      exercises: [
        { name: 'Squats', type: 'timer', workSeconds: 30, restSeconds: 10, sets: 1 },
        { name: 'Plank', type: 'timer', workSeconds: 30, restSeconds: 0, sets: 1 },
      ],
    }],
  };
  let state = start(workout);
  assert.deepEqual(where(state), ['work', 0, 0, 0, 0, 30]);
  state = advanceWork(state);
  assert.deepEqual(where(state), ['rest', 0, 0, 0, 0, 10]);
  state = finishRest(state);
  assert.deepEqual(where(state), ['work', 0, 0, 1, 0, 30]);
  state = advanceWork(state);
  assert.deepEqual(where(state), ['rest', 0, 0, 1, 0, 60]);
  state = finishRest(state);
  assert.deepEqual(where(state), ['work', 0, 1, 0, 0, 30]);
  state = finishRest(advanceWork(state));
  assert.deepEqual(where(state), ['work', 0, 1, 1, 0, 30]);
  assert.equal(advanceWork(state).phase, 'done');
});

test('an empty circuit is skipped', () => {
  const workout = {
    blocks: [
      { type: 'circuit', rounds: 3, exercises: [] },
      { type: 'exercise', exercise: { name: 'Plank', type: 'timer', workSeconds: 45, sets: 1 } },
    ],
  };
  assert.deepEqual(where(start(workout)), ['work', 1, 0, 0, 0, 45]);
});
