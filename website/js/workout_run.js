import { newId, workoutStations } from './snapshot.js';
import {
  keepAwake,
  letSleep,
  playTone,
  prepareSound,
  setTimerOpen,
} from './timer_screen.js';
import { renderRun, showRunPanel } from './workout_run_view.js';
import {
  advanceWork,
  blankRun,
  completeSet,
  enterBlock,
  finishRest,
} from './workout_steps.js';

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
  setTimerOpen(false);
  document.title = 'StackFit';
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
  letSleep();
}
