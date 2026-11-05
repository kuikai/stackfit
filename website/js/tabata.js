import { hideAppearance } from './appearance.js';
import { formatDuration } from './snapshot.js';
import {
  addFinishedTabata,
  classicTabata,
  nextTabataStep,
  setupError,
  tabataNextLabel,
  tabataTotalSeconds,
} from './tabata_rules.js';
import {
  formatClock,
  keepAwake,
  letSleep,
  playTone,
  prepareSound,
  setPhaseBar,
  setTimerOpen,
} from './timer_screen.js';

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
  document.querySelector('#tabata-form').addEventListener('input', showTotal);
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
  hideAppearance();
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

function fillClassic() {
  document.querySelector('#tabata-work').value = String(classicTabata.work);
  document.querySelector('#tabata-rest').value = String(classicTabata.rest);
  document.querySelector('#tabata-rounds').value = String(classicTabata.rounds);
  showTotal();
}

function showTotal() {
  const setup = readSetup();
  const total = document.querySelector('#tabata-total');
  total.textContent = setupError(setup) ? '' : `Total ${formatClock(tabataTotalSeconds(setup))}`;
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

function togglePause() {
  if (!run || run.phase === 'done') {
    return;
  }
  run.paused = !run.paused;
  if (!run.paused) {
    run.endsAt = Date.now() + run.remaining * 1000;
  }
  document.querySelector('#tabata-pause').textContent = run.paused ? 'Resume' : 'Pause';
  renderRun();
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
  const total = run.phase === 'rest' ? run.rest : run.work;
  document.querySelector('#tabata-phase').textContent = run.paused ? 'Paused' : phase;
  document.querySelector('#tabata-clock').textContent = formatClock(run.remaining);
  document.querySelector('#tabata-round').textContent = `Round ${run.roundIndex + 1} of ${run.rounds}`;
  document.querySelector('#tabata-exercise').textContent = run.name;
  document.querySelector('#tabata-next').textContent = tabataNextLabel(run);
  document.querySelector('#tabata-run').className = `timer-screen ${run.phase}${run.paused ? ' paused' : ''}`;
  setPhaseBar(document.querySelector('#tabata-bar'), run.remaining, total);
  document.title = `${formatClock(run.remaining)} ${phase}`;
}

function finishRun() {
  stopClock();
  setTimerOpen(false);
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
  setTimerOpen(false);
  document.querySelector('#tabata-setup').hidden = false;
  document.querySelector('#tabata-run').hidden = true;
  document.querySelector('#tabata-done').hidden = true;
  document.title = 'StackFit';
  showTotal();
}

function showRun() {
  document.querySelector('#tabata-setup').hidden = true;
  document.querySelector('#tabata-done').hidden = true;
  document.querySelector('#tabata-run').hidden = false;
  document.querySelector('#tabata-pause').textContent = 'Pause';
  setTimerOpen(true);
}

function stopClock() {
  if (run?.timer) {
    window.clearInterval(run.timer);
    run.timer = 0;
  }
  letSleep();
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
