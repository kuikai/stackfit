import { AccountApi } from './api.js';
import { installAuth } from './auth.js';
import { renderLibrary as drawLibrary } from './library.js';
import {
  bindExerciseActions,
  closeWorkoutEditor,
  openWorkoutEditor,
  readWorkoutDraft,
  workoutError,
} from './editor.js';
import { installSession } from './session.js';
import { cloneSnapshot, emptySnapshot } from './snapshot.js';
import {
  installSharing,
  openPublicShare,
  shareTokenFromPath,
} from './sharing.js';
import { installTabata, isTabataPath, openTabata, stopTabata } from './tabata.js';
import { installWorkoutRun, stopWorkout } from './workout_run.js';

const api = new AccountApi();
const account = loadAccount();

const signedOut = document.querySelector('#signed-out');
const signedIn = document.querySelector('#signed-in');
const library = document.querySelector('#library');
const sessionEditor = document.querySelector('#session-editor');

document.querySelector('#refresh').addEventListener('click', () => refresh());
document.querySelector('#new-workout').addEventListener('click', onCreateWorkout);
document.querySelector('#workout-form').addEventListener('submit', onSaveWorkout);
document.querySelector('#cancel-editor').addEventListener('click', showLibrary);
document.querySelector('#delete-workout').addEventListener('click', onDeleteWorkout);
document.querySelector('#cancel-session').addEventListener('click', showLibrary);
document.querySelector('#show-sign-up').addEventListener('click', () => showAuth('sign-up-panel'));
document.querySelector('#show-sign-in').addEventListener('click', () => showAuth('sign-in-panel'));
document.querySelector('#show-reset').addEventListener('click', () => showAuth('reset-panel'));
document.querySelector('#reset-back').addEventListener('click', () => showAuth('sign-in-panel'));
bindExerciseActions();

const sharingApp = {
  account,
  api,
  localWorkout: null,
  showBanner,
  clearBanner,
  showLibrary,
  promptSignIn,
  openEditor,
  renderLibrary: () => drawLibrary(account, sharingApp),
  loadAccountData,
  loadShares,
  persist,
  cloneSnapshot,
  closeWorkoutEditor,
  clearAccount,
  showAuth,
  showSignedOut,
  storeAccount,
  refresh,
};
installAuth(sharingApp);
installSharing(sharingApp);
installSession(sharingApp);
installTabata(sharingApp);
installWorkoutRun(sharingApp);

const openedShare = shareTokenFromPath();
if (isTabataPath()) {
  openTabata(sharingApp);
} else if (openedShare) {
  openPublicShare(openedShare, sharingApp);
} else if (account.token) {
  refresh().catch((error) => {
    clearAccount();
    showSignedOut(error.message);
  });
} else {
  showSignedOut('');
}

async function refresh() {
  const editing = !document.querySelector('#editor').hidden || !sessionEditor.hidden;
  const running = !document.querySelector('#workout-run').hidden;
  if (editing && !window.confirm('Discard this edit and refresh?')) {
    return;
  }
  if (running && !window.confirm('Stop this workout and refresh?')) {
    return;
  }
  setStatus('Loading');
  await loadAccountData();
  showLibrary();
  drawLibrary(account, sharingApp);
  setStatus('Saved');
}

async function loadAccountData() {
  const data = await api.load(account.token);
  account.revision = data.revision;
  account.snapshot = data.snapshot;
  if (data.displayName) {
    account.displayName = data.displayName;
  }
  await loadShares();
}

async function loadShares() {
  const listed = await api.listShares(account.token);
  account.shares = listed.shares || [];
}

function onCreateWorkout() {
  clearBanner();
  openEditor(null);
}

async function onSaveWorkout(event) {
  event.preventDefault();
  const workout = readWorkoutDraft();
  const error = workoutError(workout);
  if (error) {
    showBanner(error);
    return;
  }
  const snapshot = cloneSnapshot(account.snapshot);
  const index = snapshot.workouts.findIndex((item) => item.id === workout.id);
  if (index >= 0) {
    snapshot.workouts[index] = workout;
  } else {
    snapshot.workouts.push(workout);
  }
  await persist(snapshot, 'Saved. The app shows this the next time it syncs.');
}

async function onDeleteWorkout() {
  const workout = readWorkoutDraft();
  const confirmed = window.confirm(`Delete ${workout.name || 'this workout'}?`);
  if (!confirmed) {
    return;
  }
  const snapshot = cloneSnapshot(account.snapshot);
  snapshot.workouts = snapshot.workouts.filter((item) => item.id !== workout.id);
  snapshot.deletedWorkouts = snapshot.deletedWorkouts.filter((item) => item.id !== workout.id);
  snapshot.deletedWorkouts.push({
    id: workout.id,
    deletedAt: new Date().toISOString(),
  });
  await persist(snapshot, 'Deleted. The app drops it the next time it syncs.');
}

async function persist(snapshot, notice) {
  clearBanner();
  setStatus('Saving');
  try {
    const saved = await api.save(account.token, account.revision, snapshot);
    account.revision = saved.revision;
    account.snapshot = saved.snapshot;
    showLibrary();
    drawLibrary(account, sharingApp);
    setStatus('Saved');
    if (notice) {
      showBanner(notice, 'ok');
    }
  } catch (error) {
    setStatus('Not saved');
    if (error.message === 'Sign in again.') {
      clearAccount();
      showSignedOut(error.message);
      return;
    }
    showBanner(error.message);
  }
}
function openEditor(workout) {
  clearBanner();
  library.hidden = true;
  sessionEditor.hidden = true;
  document.querySelector('#share-link-box').hidden = true;
  openWorkoutEditor(workout);
}

function showLibrary() {
  stopTabata();
  stopWorkout();
  closeWorkoutEditor();
  sessionEditor.hidden = true;
  library.hidden = false;
  document.querySelector('#receive').hidden = false;
  document.querySelector('#share-view').hidden = true;
  document.querySelector('#tabata').hidden = true;
  document.querySelector('#progress-picker').hidden = true;
  signedIn.hidden = false;
  signedOut.hidden = true;
  document.querySelector('#account-bar').hidden = false;
}

function promptSignIn(message) {
  signedOut.hidden = false;
  document.querySelector('#account-bar').hidden = true;
  showAuth('sign-in-panel');
  if (message) {
    showBanner(message, 'ok');
  }
}

function showAuth(panelId) {
  for (const id of ['sign-in-panel', 'sign-up-panel', 'reset-panel']) {
    document.querySelector(`#${id}`).hidden = id !== panelId;
  }
  clearBanner();
}

function showSignedOut(message) {
  stopTabata();
  stopWorkout();
  signedOut.hidden = false;
  signedIn.hidden = true;
  document.querySelector('#share-view').hidden = true;
  document.querySelector('#tabata').hidden = true;
  document.querySelector('#account-bar').hidden = true;
  showAuth('sign-in-panel');
  if (message) {
    showBanner(message);
  }
}

function storeAccount(data) {
  account.token = data.token;
  account.email = data.user?.email || '';
  account.displayName = data.user?.displayName || '';
  sessionStorage.setItem('stackfit.token', account.token);
  sessionStorage.setItem('stackfit.email', account.email);
}

function loadAccount() {
  return {
    token: sessionStorage.getItem('stackfit.token') || '',
    email: sessionStorage.getItem('stackfit.email') || '',
    displayName: '',
    revision: 0,
    snapshot: emptySnapshot(),
    shares: [],
  };
}

function clearAccount() {
  account.token = '';
  account.email = '';
  account.revision = 0;
  account.snapshot = emptySnapshot();
  account.shares = [];
  sessionStorage.removeItem('stackfit.token');
  sessionStorage.removeItem('stackfit.email');
}

function setStatus(text) {
  document.querySelector('#save-status').textContent = text;
}

function showBanner(message, kind = 'error') {
  const banner = document.querySelector('#banner');
  banner.hidden = false;
  banner.className = `banner ${kind}`;
  banner.textContent = message;
}

function clearBanner() {
  const banner = document.querySelector('#banner');
  banner.hidden = true;
  banner.textContent = '';
}
