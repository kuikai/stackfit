import { newId } from './snapshot.js';

export const classicTabata = { work: 20, rest: 10, rounds: 8 };

export function tabataTotalSeconds(setup) {
  return setup.rounds * setup.work + Math.max(0, setup.rounds - 1) * setup.rest;
}

export function setupError(setup) {
  if (!Number.isInteger(setup.work) || setup.work < 1 || setup.work > 3600) {
    return 'Work time must be between 1 second and 60 minutes.';
  }
  if (!Number.isInteger(setup.rest) || setup.rest < 0 || setup.rest > 600) {
    return 'Rest time must be between 0 and 10 minutes.';
  }
  if (!Number.isInteger(setup.rounds) || setup.rounds < 1 || setup.rounds > 99) {
    return 'Rounds must be between 1 and 99.';
  }
  return '';
}

export function nextTabataStep(current) {
  if (current.phase === 'work' && !isLastRound(current) && current.rest > 0) {
    return { ...current, phase: 'rest', remaining: current.rest };
  }
  return nextRound(current);
}

function isLastRound(current) {
  return current.roundIndex >= current.rounds - 1;
}

function nextRound(current) {
  const roundIndex = current.roundIndex + 1;
  if (roundIndex >= current.rounds) {
    return { ...current, phase: 'done', remaining: 0 };
  }
  return {
    ...current,
    phase: 'work',
    roundIndex,
    remaining: current.work,
  };
}

export function tabataNextLabel(current) {
  if (current.phase === 'rest') {
    return `Next: round ${current.roundIndex + 2} of ${current.rounds}`;
  }
  if (isLastRound(current)) {
    return 'Last round';
  }
  return current.rest > 0 ? `Then ${current.rest}s rest` : 'Next round straight after';
}

export function addFinishedTabata(snapshot, finished) {
  const now = new Date().toISOString();
  const workoutId = newId();
  snapshot.workouts.push({
    id: workoutId,
    name: finished.name,
    createdAt: now,
    updatedAt: now,
    exercises: [timerExercise(finished)],
  });
  snapshot.sessions.push({
    id: newId(),
    workoutId,
    workoutName: finished.name,
    completedAt: now,
    durationSeconds: Math.max(1, finished.elapsed),
    totalExercises: 1,
  });
}

function timerExercise(finished) {
  return {
    id: newId(),
    name: finished.name,
    type: 'timer',
    workSeconds: finished.work,
    restSeconds: finished.rest,
    sets: finished.rounds,
    reps: null,
  };
}
