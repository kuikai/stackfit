import { workoutBlocks } from './snapshot.js';

export function enterBlock(state, blockIndex) {
  const blocks = workoutBlocks(state.workout);
  if (blockIndex >= blocks.length) {
    return doneState(state, blockIndex);
  }
  const block = blocks[blockIndex];
  if (block.type === 'circuit' && !(block.exercises || []).length) {
    return enterBlock(state, blockIndex + 1);
  }
  return openExercise(state, blockIndex, 0, 0);
}

export function enterExercise(state, index) {
  return enterBlock(state, index);
}

export function advanceWork(state) {
  const exercise = currentExercise(state);
  const rest = exercise?.restSeconds ?? 0;
  const rounds = exercise?.sets ?? 1;
  const lastRound = state.setIndex >= rounds - 1;
  if (!lastRound) {
    if (rest > 0) {
      return restState(state, rest, 'timerRound');
    }
    return nextTimerRound(state);
  }
  return leaveStation(state, false);
}

export function completeSet(state) {
  const exercise = currentExercise(state);
  const total = exercise?.sets ?? 1;
  const lastSet = state.setIndex >= total - 1;
  if (lastSet) {
    return leaveStation(state, true);
  }
  return beginRest(state, exercise?.restSeconds ?? 0, 'set');
}

export function finishRest(state) {
  const after = state.afterRest || 'block';
  return applyAfterRest({ ...state, afterRest: 'block' }, after);
}

export function blankRun(workout) {
  return {
    workout,
    blockIndex: 0,
    roundIndex: 0,
    exerciseIndex: 0,
    setIndex: 0,
    phase: 'work',
    remaining: 0,
    paused: false,
    afterRest: 'block',
  };
}

function openExercise(state, blockIndex, roundIndex, exerciseIndex) {
  const next = {
    ...state,
    blockIndex,
    roundIndex,
    exerciseIndex,
    setIndex: 0,
    paused: false,
  };
  const exercise = currentExercise(next);
  if (!exercise) {
    return enterBlock(next, blockIndex + 1);
  }
  if (exercise.type === 'timer') {
    return armTimer(next, exercise);
  }
  return { ...next, phase: 'set', remaining: 0 };
}

function armTimer(state, exercise) {
  const work = exercise.workSeconds ?? 0;
  const rest = exercise.restSeconds ?? 0;
  if (work > 0) {
    return { ...state, phase: 'work', remaining: work };
  }
  if (rest > 0) {
    return restState(state, rest, 'timerRound');
  }
  return leaveStation(state, false);
}

function leaveStation(state, restAfterLastSet) {
  const exit = planStationExit(state, restAfterLastSet);
  return beginRest(state, exit.restSeconds, exit.destination);
}

function beginRest(state, seconds, after) {
  if (seconds <= 0) {
    return applyAfterRest(state, after);
  }
  return restState(state, seconds, after);
}

function restState(state, seconds, after) {
  return { ...state, phase: 'rest', remaining: seconds, paused: false, afterRest: after };
}

function applyAfterRest(state, after) {
  if (after === 'timerRound') {
    return nextTimerRound(state);
  }
  if (after === 'set') {
    return { ...state, setIndex: state.setIndex + 1, phase: 'set', remaining: 0, paused: false };
  }
  if (after === 'station') {
    return openExercise(state, state.blockIndex, state.roundIndex, state.exerciseIndex + 1);
  }
  if (after === 'round') {
    return openExercise(state, state.blockIndex, state.roundIndex + 1, 0);
  }
  return enterBlock(state, state.blockIndex + 1);
}

function planStationExit(state, restAfterLastSet) {
  const block = workoutBlocks(state.workout)[state.blockIndex];
  const exercise = currentExercise(state);
  const stationRest = restAfterLastSet ? Math.max(0, exercise?.restSeconds ?? 0) : 0;
  if (!block || block.type !== 'circuit') {
    return { destination: 'block', restSeconds: stationRest };
  }
  const count = block.exercises?.length ?? 0;
  const lastStation = state.exerciseIndex >= count - 1;
  const rounds = Math.max(1, block.rounds || 1);
  if (!lastStation) {
    return { destination: 'station', restSeconds: Math.max(0, exercise?.restSeconds ?? 0) };
  }
  if (state.roundIndex < rounds - 1) {
    return {
      destination: 'round',
      restSeconds: Math.max(0, block.restBetweenRoundsSeconds || 0),
    };
  }
  return { destination: 'block', restSeconds: stationRest };
}

function doneState(state, blockIndex) {
  return { ...state, blockIndex, phase: 'done', remaining: 0, paused: false };
}

function nextTimerRound(state) {
  const exercise = currentExercise(state);
  const work = exercise?.workSeconds ?? 0;
  const nextRound = state.setIndex + 1;
  const total = exercise?.sets ?? 1;
  if (nextRound >= total || work <= 0) {
    return leaveStation(state, false);
  }
  return {
    ...state,
    setIndex: nextRound,
    phase: 'work',
    remaining: work,
    paused: false,
  };
}

function currentExercise(state) {
  const block = workoutBlocks(state.workout)[state.blockIndex];
  if (!block) {
    return undefined;
  }
  if (block.type === 'circuit') {
    return block.exercises?.[state.exerciseIndex];
  }
  return block.exercise;
}
