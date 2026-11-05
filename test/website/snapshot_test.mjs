import assert from 'node:assert/strict';
import { test } from 'node:test';

import { mergeSnapshots } from '../../website/js/snapshot.js';

function workout(id, name, updatedAt) {
  return { id, name, updatedAt, exercises: [] };
}

test('a newer home order wins and keeps a newer edit', () => {
  const merged = mergeSnapshots(
    {
      workouts: [
        workout('b', 'Beta', '2026-01-01T00:00:00.000Z'),
        workout('a', 'Old', '2026-01-01T00:00:00.000Z'),
      ],
      homeOrderUpdatedAt: '2026-06-01T00:00:00.000Z',
    },
    {
      workouts: [
        workout('a', 'New', '2026-02-01T00:00:00.000Z'),
        workout('b', 'Beta', '2026-01-01T00:00:00.000Z'),
        workout('c', 'Cee', '2026-03-01T00:00:00.000Z'),
      ],
      homeOrderUpdatedAt: '2026-01-01T00:00:00.000Z',
    },
  );

  assert.deepEqual(merged.workouts.map((item) => item.id), ['b', 'a', 'c']);
  assert.equal(merged.workouts.find((item) => item.id === 'a').name, 'New');
  assert.equal(merged.homeOrderUpdatedAt, '2026-06-01T00:00:00.000Z');
});

function session(id, setLogs) {
  return {
    id,
    workoutId: 'workout',
    workoutName: 'Push',
    completedAt: id === 'session-2' ? '2026-02-02T00:00:00.000Z' : '2026-01-01T00:00:00.000Z',
    durationSeconds: 60,
    totalExercises: 1,
    setLogs,
  };
}

test('a session deletion removes that history row', () => {
  const merged = mergeSnapshots(
    { sessions: [session('session-1'), session('session-2')] },
    { deletedSessions: [{ id: 'session-1', deletedAt: '2026-03-01T00:00:00.000Z' }] },
  );
  assert.deepEqual(merged.sessions.map((item) => item.id), ['session-2']);
  assert.equal(merged.deletedSessions[0].id, 'session-1');
});

test('a session only one side has is kept', () => {
  const merged = mergeSnapshots(
    { sessions: [session('session-1')] },
    {},
  );
  assert.equal(merged.sessions[0].id, 'session-1');
  assert.deepEqual(merged.deletedSessions, []);
});

test('a set removed on one side stays removed', () => {
  const squat = { exerciseId: 'squat', setNumber: 1, reps: 5, round: 1 };
  const secondRound = { exerciseId: 'squat', setNumber: 1, reps: 5, round: 2 };
  const merged = mergeSnapshots(
    { sessions: [session('session-1', [squat])] },
    { sessions: [session('session-1', [squat, secondRound])] },
  );
  assert.deepEqual(merged.sessions[0].setLogs.map((log) => log.round), [1]);
});

test('without a home order, workouts sort by name', () => {
  const merged = mergeSnapshots(
    {
      workouts: [
        workout('z', 'Zebra', '2026-01-01T00:00:00.000Z'),
        workout('a', 'Alpha', '2026-01-01T00:00:00.000Z'),
      ],
    },
    { workouts: [workout('a', 'Alpha', '2026-01-01T00:00:00.000Z')] },
  );

  assert.deepEqual(merged.workouts.map((item) => item.name), ['Alpha', 'Zebra']);
  assert.equal(merged.homeOrderUpdatedAt, '1970-01-01T00:00:00.000Z');
});
