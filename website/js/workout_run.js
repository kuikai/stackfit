import { newId } from './snapshot.js';

let audio;
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
  if (!workout.exercises?.length) {
    app.showBanner('Add an exercise before running this workout.');
    return;
  }
  app.clearBanner();
  stopClock();
  run = {
    ...enterExercise(blankRun(workout), 0),
    startedAt: Date.now(),
  };
  prepareSound();
  keepAwake();
  showRunPanel();
  armClock(app);
  renderRun();
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

export function enterExercise(state, index) {
  const exercises = state.workout.exercises || [];
  if (index >= exercises.length) {
    return { ...state, exerciseIndex: index, phase: 'done', remaining: 0, paused: false };
  }
  const exercise = exercises[index];
  const base = {
    ...state,
    exerciseIndex: index,
    setIndex: 0,
    paused: false,
    restAfterLastSet: false,
  };
  if (exercise.type !== 'timer') {
    return { ...base, phase: 'set', remaining: 0 };
  }
  return enterTimer(base, exercise);
}

export function advanceWork(state) {
  const exercise = currentExercise(state);
  const rest = exercise?.restSeconds ?? 0;
  const rounds = exercise?.sets ?? 1;
  const lastRound = state.setIndex >= rounds - 1;
  if (lastRound) {
    return enterExercise(state, state.exerciseIndex + 1);
  }
  if (rest > 0) {
    return { ...state, phase: 'rest', remaining: rest, paused: false, restAfterLastSet: false };
  }
  return nextTimerRound(state);
}

export function completeSet(state) {
  const exercise = currentExercise(state);
  const total = exercise?.sets ?? 1;
  const lastSet = state.setIndex >= total - 1;
  const rest = exercise?.restSeconds ?? 0;
  if (rest > 0) {
    return { ...state, phase: 'rest', remaining: rest, paused: false, restAfterLastSet: lastSet };
  }
  if (lastSet) {
    return enterExercise(state, state.exerciseIndex + 1);
  }
  return { ...state, setIndex: state.setIndex + 1, phase: 'set', remaining: 0, paused: false };
}

export function finishRest(state) {
  const exercise = currentExercise(state);
  if (exercise?.type === 'timer') {
    return nextTimerRound(state);
  }
  if (exercise?.type === 'sets' && !state.restAfterLastSet) {
    return { ...state, setIndex: state.setIndex + 1, phase: 'set', remaining: 0, paused: false };
  }
  return enterExercise(state, state.exerciseIndex + 1);
}

function blankRun(workout) {
  return {
    workout,
    exerciseIndex: 0,
    setIndex: 0,
    phase: 'work',
    remaining: 0,
    paused: false,
    restAfterLastSet: false,
  };
}

function enterTimer(state, exercise) {
  const work = exercise.workSeconds ?? 0;
  const rest = exercise.restSeconds ?? 0;
  if (work > 0) {
    return { ...state, phase: 'work', remaining: work };
  }
  if (rest > 0) {
    return { ...state, phase: 'rest', remaining: rest };
  }
  return enterExercise(state, state.exerciseIndex + 1);
}

function nextTimerRound(state) {
  const exercise = currentExercise(state);
  const work = exercise?.workSeconds ?? 0;
  const nextRound = state.setIndex + 1;
  const total = exercise?.sets ?? 1;
  if (nextRound >= total || work <= 0) {
    return enterExercise(state, state.exerciseIndex + 1);
  }
  return {
    ...state,
    setIndex: nextRound,
    phase: 'work',
    remaining: work,
    paused: false,
    restAfterLastSet: false,
  };
}

function currentExercise(state) {
  return state.workout.exercises?.[state.exerciseIndex];
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
  renderRun();
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
    renderRun();
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
  renderRun();
}

function renderRun() {
  const exercise = currentExercise(run);
  const panel = document.querySelector('#workout-run');
  panel.hidden = false;
  panel.className = `panel tabata-run ${run.phase}`;
  document.querySelector('#run-progress').textContent = progressLabel(run);
  document.querySelector('#run-name').textContent = exercise?.name || run.workout.name;
  document.querySelector('#run-phase').textContent = phaseLabel(run.phase);
  document.querySelector('#run-detail').textContent = detailLabel(run, exercise);
  const clockNode = document.querySelector('#run-clock');
  clockNode.textContent = run.phase === 'set' ? setLabel(run, exercise) : formatClock(run.remaining);
  clockNode.className = run.phase === 'set' ? 'tabata-clock set-prompt' : 'tabata-clock';
  renderControls();
  if (run.phase === 'work' || run.phase === 'rest') {
    document.title = `${formatClock(run.remaining)} ${phaseLabel(run.phase)}`;
  }
}

function renderControls() {
  const primary = document.querySelector('#run-primary');
  const pause = document.querySelector('#run-pause');
  primary.hidden = run.phase === 'work';
  primary.textContent = run.phase === 'rest' ? 'Skip rest' : 'Done';
  pause.hidden = run.phase === 'set';
  pause.textContent = run.paused ? 'Resume' : 'Pause';
}

function progressLabel(state) {
  const total = state.workout.exercises.length;
  const number = Math.min(state.exerciseIndex + 1, total);
  return `Exercise ${number} of ${total}`;
}

function phaseLabel(phase) {
  if (phase === 'rest') {
    return 'Rest';
  }
  if (phase === 'set') {
    return 'Set';
  }
  return 'Work';
}

function detailLabel(state, exercise) {
  if (!exercise) {
    return '';
  }
  if (state.phase === 'set') {
    return exercise.reps ? `${exercise.reps} reps` : '';
  }
  const total = exercise.sets ?? 1;
  if (total > 1) {
    return `Set ${state.setIndex + 1} of ${total}`;
  }
  return '';
}

function setLabel(state, exercise) {
  const total = exercise?.sets ?? 1;
  return `Set ${state.setIndex + 1} of ${total}`;
}

function formatClock(totalSeconds) {
  const safe = Math.max(0, totalSeconds);
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

function showRunPanel() {
  document.querySelector('#library').hidden = true;
  document.querySelector('#receive').hidden = true;
  document.querySelector('#share-link-box').hidden = true;
  document.querySelector('#progress-picker').hidden = true;
  document.querySelector('#editor').hidden = true;
  document.querySelector('#session-editor').hidden = true;
  document.querySelector('#workout-run').hidden = false;
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
    totalExercises: finished.workout.exercises.length,
  });
  await app.persist(snapshot, 'Saved. The app shows this session the next time it syncs.');
}

function stopClock() {
  window.clearInterval(clock);
  clock = 0;
  wakeLock?.release?.().catch(() => {});
  wakeLock = null;
}

function prepareSound() {
  const Context = window.AudioContext || window.webkitAudioContext;
  if (!Context || audio) {
    return;
  }
  audio = new Context();
}

function playTone(frequency) {
  if (!audio) {
    return;
  }
  const tone = audio.createOscillator();
  const gain = audio.createGain();
  tone.frequency.value = frequency;
  gain.gain.value = 0.04;
  tone.connect(gain);
  gain.connect(audio.destination);
  tone.start();
  tone.stop(audio.currentTime + 0.12);
}

async function keepAwake() {
  try {
    wakeLock = await navigator.wakeLock?.request('screen');
  } catch {
    wakeLock = null;
  }
}
