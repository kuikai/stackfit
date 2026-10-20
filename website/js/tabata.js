import { formatDuration, newId } from './snapshot.js';

const classicTabata = { work: 20, rest: 10, rounds: 8 };

let audio;
let wakeLock;
let run;

export function isTabataPath() {
  return window.location.pathname === '/tabata';
}

export function installTabata(app) {
  document.querySelector('#tabata-classic').addEventListener('click', fillClassic);
  document.querySelector('#tabata-form').addEventListener('submit', (event) => {
    event.preventDefault();
    startFromForm(app);
  });
  document.querySelector('#tabata-pause').addEventListener('click', togglePause);
  document.querySelector('#tabata-stop').addEventListener('click', () => stopToSetup());
  document.querySelector('#tabata-again').addEventListener('click', () => stopToSetup());
  document.querySelector('#tabata-save').addEventListener('click', () => saveFinished(app));
  document.addEventListener('keydown', onTimerKey);
}

export function openTabata(app) {
  stopClock();
  document.querySelector('#signed-in').hidden = true;
  document.querySelector('#signed-out').hidden = true;
  document.querySelector('#share-view').hidden = true;
  document.querySelector('#tabata').hidden = false;
  document.querySelector('#tabata-save').hidden = !app.account.token;
  document.querySelector('#tabata-signin').hidden = Boolean(app.account.token);
  if (app.account.token) {
    document.querySelector('#account-bar').hidden = false;
    document.querySelector('#account-email').textContent = app.account.email;
    app.loadAccountData().catch(() => {
      app.clearAccount();
      document.querySelector('#account-bar').hidden = true;
      document.querySelector('#tabata-save').hidden = true;
      document.querySelector('#tabata-signin').hidden = false;
    });
  }
  showSetup();
}

export function stopTabata() {
  stopClock();
}

export function nextTabataStep(current) {
  if (current.phase === 'work' && !isLastRound(current) && current.rest > 0) {
    return { ...current, phase: 'rest', remaining: current.rest };
  }
  return nextRound(current);
}

function fillClassic() {
  document.querySelector('#tabata-work').value = String(classicTabata.work);
  document.querySelector('#tabata-rest').value = String(classicTabata.rest);
  document.querySelector('#tabata-rounds').value = String(classicTabata.rounds);
}

function startFromForm(app) {
  const setup = readSetup();
  const error = setupError(setup);
  if (error) {
    app.showBanner(error);
    return;
  }
  app.clearBanner();
  beginRun(setup);
}

function readSetup() {
  return {
    name: document.querySelector('#tabata-name').value.trim() || 'Tabata',
    work: wholeNumber('#tabata-work'),
    rest: wholeNumber('#tabata-rest'),
    rounds: wholeNumber('#tabata-rounds'),
  };
}

function wholeNumber(selector) {
  return Number(document.querySelector(selector).value);
}

function setupError(setup) {
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

function beginRun(setup) {
  run = {
    ...setup,
    phase: 'work',
    roundIndex: 0,
    remaining: setup.work,
    elapsed: 0,
    paused: false,
    endsAt: Date.now() + setup.work * 1000,
    timer: 0,
  };
  prepareSound();
  keepAwake();
  showRun();
  renderRun();
  run.timer = window.setInterval(onTick, 200);
}

function onTick() {
  if (!run || run.paused) {
    return;
  }
  const left = Math.max(0, Math.ceil((run.endsAt - Date.now()) / 1000));
  if (left !== run.remaining) {
    run.elapsed += run.remaining - left;
    run.remaining = left;
    renderRun();
  }
  if (left > 0) {
    return;
  }
  const next = nextTabataStep(run);
  Object.assign(run, next);
  playTone(run.phase === 'done' ? 880 : 660);
  if (run.phase === 'done') {
    finishRun();
    return;
  }
  run.endsAt = Date.now() + run.remaining * 1000;
  renderRun();
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

function togglePause() {
  if (!run || run.phase === 'done') {
    return;
  }
  run.paused = !run.paused;
  if (!run.paused) {
    run.endsAt = Date.now() + run.remaining * 1000;
  }
  document.querySelector('#tabata-pause').textContent = run.paused ? 'Resume' : 'Pause';
}

function onTimerKey(event) {
  const running = !document.querySelector('#tabata-run').hidden;
  if (event.code !== 'Space' || !running || event.target.matches('input, textarea, select')) {
    return;
  }
  event.preventDefault();
  togglePause();
}

function renderRun() {
  const phase = run.phase === 'rest' ? 'Rest' : 'Work';
  document.querySelector('#tabata-phase').textContent = phase;
  document.querySelector('#tabata-clock').textContent = formatClock(run.remaining);
  document.querySelector('#tabata-round').textContent = `Round ${run.roundIndex + 1} of ${run.rounds}`;
  document.querySelector('#tabata-exercise').textContent = run.name;
  document.querySelector('#tabata-run').className = `panel tabata-run ${run.phase}`;
  document.title = `${formatClock(run.remaining)} ${phase}`;
}

function finishRun() {
  stopClock();
  document.querySelector('#tabata-run').hidden = true;
  document.querySelector('#tabata-done').hidden = false;
  document.querySelector('#tabata-done-time').textContent = formatDuration(run.elapsed);
  document.title = 'StackFit';
}

function stopToSetup() {
  stopClock();
  run = null;
  showSetup();
}

function showSetup() {
  document.querySelector('#tabata-setup').hidden = false;
  document.querySelector('#tabata-run').hidden = true;
  document.querySelector('#tabata-done').hidden = true;
  document.title = 'StackFit';
}

function showRun() {
  document.querySelector('#tabata-setup').hidden = true;
  document.querySelector('#tabata-done').hidden = true;
  document.querySelector('#tabata-run').hidden = false;
  document.querySelector('#tabata-pause').textContent = 'Pause';
}

function stopClock() {
  if (run?.timer) {
    window.clearInterval(run.timer);
    run.timer = 0;
  }
  wakeLock?.release?.().catch(() => {});
  wakeLock = null;
}

function formatClock(totalSeconds) {
  const safe = Math.max(0, totalSeconds);
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
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

async function saveFinished(app) {
  if (!run || run.phase !== 'done') {
    return;
  }
  if (!app.account.token) {
    app.promptSignIn('Sign in to keep this workout on your phone.');
    return;
  }
  try {
    await app.loadAccountData();
    const snapshot = app.cloneSnapshot(app.account.snapshot);
    addFinishedTabata(snapshot, run);
    await app.persist(snapshot, 'Saved. The app shows it the next time it syncs.');
    if (window.location.pathname === '/tabata') {
      window.history.pushState({}, '', '/');
    }
  } catch (error) {
    app.showBanner(error.message);
  }
}

function addFinishedTabata(snapshot, finished) {
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
