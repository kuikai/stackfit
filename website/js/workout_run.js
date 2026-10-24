import { newId, workoutBlocks, workoutStations } from './snapshot.js';
import { playTone, prepareSound, renderRun, showRunPanel } from './workout_run_view.js';

let wakeLock;
let run;
let clock;

export function installWorkoutRun(app) {
  document.querySelector('#run-primary').addEventListener('click', () => onPrimary(app));
  document.querySelector('#run-pause').addEventListener('click', () => toggleRunPause());
  document.querySelector('#run-skip').addEventListener('click', () => skipCurrent(app));
  document.querySelector('#run-stop').addEventListener('click', () => app.showLibrary());
  document.addEventListener('keydown', (event) => onRunKey(event, app));
}

export function startWorkout(workout, app) {
  if (!workoutStations(workout).length) {
    app.showBanner('Add an exercise before running this workout.');
    return;
  }
  app.clearBanner();
  stopClock();
  run = {
    ...enterBlock(blankRun(workout), 0),
    startedAt: Date.now(),
  };
  prepareSound();
  keepAwake();
  showRunPanel();
  armClock(app);
  renderRun(run);
}

export function stopWorkout() {
  stopClock();
  run = null;
  const panel = document.querySelector('#workout-run');
  if (panel) {
    panel.hidden = true;
  }
  document.title = 'StackFit';
}

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

function blankRun(workout) {
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

function onPrimary(app) {
  if (!run || run.phase === 'done') {
    return;
  }
  if (run.phase === 'set') {
    applyStep(completeSet(run), app);
    return;
  }
  if (run.phase === 'rest') {
    applyStep(finishRest(run), app);
  }
}

function skipCurrent(app) {
  if (!run || run.phase === 'done') {
    return;
  }
  if (run.phase === 'work') {
    applyStep(advanceWork(run), app);
    return;
  }
  if (run.phase === 'rest') {
    applyStep(finishRest(run), app);
    return;
  }
  applyStep(completeSet(run), app);
}

function toggleRunPause() {
  if (!run || run.phase === 'set' || run.phase === 'done') {
    return;
  }
  run.paused = !run.paused;
  if (!run.paused) {
    run.endsAt = Date.now() + run.remaining * 1000;
  }
  renderRun(run);
}

function onRunKey(event, app) {
  const panel = document.querySelector('#workout-run');
  if (!panel || panel.hidden || event.code !== 'Space' || event.target.matches('input, textarea, select')) {
    return;
  }
  event.preventDefault();
  if (run?.phase === 'set') {
    onPrimary(app);
    return;
  }
  toggleRunPause();
}

function armClock(app) {
  window.clearInterval(clock);
  if (run.phase === 'work' || run.phase === 'rest') {
    run.endsAt = Date.now() + run.remaining * 1000;
  }
  clock = window.setInterval(() => onClock(app), 200);
}

function onClock(app) {
  if (!run || run.paused || (run.phase !== 'work' && run.phase !== 'rest')) {
    return;
  }
  const left = Math.max(0, Math.ceil((run.endsAt - Date.now()) / 1000));
  if (left !== run.remaining) {
    run.remaining = left;
    renderRun(run);
  }
  if (left > 0) {
    return;
  }
  const next = run.phase === 'work' ? advanceWork(run) : finishRest(run);
  applyStep(next, app);
}

function applyStep(next, app) {
  const previous = run?.phase;
  run = { ...run, ...next, startedAt: run.startedAt };
  if (run.phase !== previous) {
    playTone(run.phase === 'done' ? 880 : 660);
  }
  if (run.phase === 'done') {
    finishWorkout(app);
    return;
  }
  if (run.phase === 'work' || run.phase === 'rest') {
    run.endsAt = Date.now() + run.remaining * 1000;
  }
  renderRun(run);
}
async function finishWorkout(app) {
  if (!run || run.phase !== 'done' || run.saving) {
    return;
  }
  run.saving = true;
  const finished = run;
  stopClock();
  document.title = 'StackFit';
  try {
    await logSession(app, finished);
  } catch (error) {
    app.showBanner(error.message);
    app.showLibrary();
  }
}

async function logSession(app, finished) {
  const elapsed = Math.max(1, Math.round((Date.now() - finished.startedAt) / 1000));
  await app.loadAccountData();
  const snapshot = app.cloneSnapshot(app.account.snapshot);
  snapshot.sessions.push({
    id: newId(),
    workoutId: finished.workout.id,
    workoutName: finished.workout.name,
    completedAt: new Date().toISOString(),
    durationSeconds: elapsed,
    totalExercises: workoutStations(finished.workout).length,
  });
  await app.persist(snapshot, 'Saved. The app shows this session the next time it syncs.');
}

function stopClock() {
  window.clearInterval(clock);
  clock = 0;
  wakeLock?.release?.().catch(() => {});
  wakeLock = null;
}
async function keepAwake() {
  try {
    wakeLock = await navigator.wakeLock?.request('screen');
  } catch {
    wakeLock = null;
  }
}
