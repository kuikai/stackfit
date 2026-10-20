import { AccountApi } from './api.js';
import {
  bindExerciseActions,
  closeWorkoutEditor,
  openWorkoutEditor,
  readWorkoutDraft,
  workoutError,
} from './editor.js';
import { installSession } from './session.js';
import {
  cloneSnapshot,
  emptySnapshot,
  estimatedDurationSeconds,
  exerciseLine,
  formatDuration,
  formatSessionDate,
} from './snapshot.js';
import {
  installSharing,
  openPublicShare,
  shareTokenFromPath,
  showLocalWorkout,
  workoutShareButtons,
} from './sharing.js';
import { installTabata, isTabataPath, openTabata, stopTabata } from './tabata.js';
import { installWorkoutRun, startWorkout, stopWorkout } from './workout_run.js';

const api = new AccountApi();
const account = loadAccount();

const signedOut = document.querySelector('#signed-out');
const signedIn = document.querySelector('#signed-in');
const library = document.querySelector('#library');
const sessionEditor = document.querySelector('#session-editor');

document.querySelector('#sign-in-form').addEventListener('submit', onSignIn);
document.querySelector('#sign-up-form').addEventListener('submit', onSignUp);
document.querySelector('#request-reset-form').addEventListener('submit', onRequestReset);
document.querySelector('#finish-reset-form').addEventListener('submit', onFinishReset);
document.querySelector('#sign-out').addEventListener('click', onSignOut);
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
  renderLibrary,
  loadAccountData,
  loadShares,
  persist,
  cloneSnapshot,
  closeWorkoutEditor,
  clearAccount,
};
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

async function onSignIn(event) {
  event.preventDefault();
  await authenticate(() => api.signIn(formValues(event.target)));
}

async function onSignUp(event) {
  event.preventDefault();
  const values = formValues(event.target);
  await authenticate(() => api.signUp(values));
}

async function authenticate(request) {
  clearBanner();
  try {
    const data = await request();
    storeAccount(data);
    const returnShare = sessionStorage.getItem('stackfit.returnShare');
    sessionStorage.removeItem('stackfit.returnShare');
    if (returnShare) {
      window.location.assign(`/s/${returnShare}`);
      return;
    }
    await refresh();
    const pendingRoutine = sessionStorage.getItem('stackfit.pendingRoutine');
    sessionStorage.removeItem('stackfit.pendingRoutine');
    if (pendingRoutine) {
      showLocalWorkout(JSON.parse(pendingRoutine), sharingApp);
    }
  } catch (error) {
    showBanner(error.message);
  }
}

async function onRequestReset(event) {
  event.preventDefault();
  clearBanner();
  try {
    const email = document.querySelector('#reset-email').value;
    await api.requestReset(email);
    showBanner('If that email has an account, the code was printed by the server.', 'ok');
  } catch (error) {
    showBanner(error.message);
  }
}

async function onFinishReset(event) {
  event.preventDefault();
  clearBanner();
  try {
    await api.resetPassword({
      email: document.querySelector('#reset-email').value,
      code: document.querySelector('#reset-code').value,
      password: document.querySelector('#reset-password').value,
    });
    showAuth('sign-in-panel');
    showBanner('Password updated. Sign in with the new password.', 'ok');
  } catch (error) {
    showBanner(error.message);
  }
}

async function onSignOut() {
  const token = account.token;
  clearAccount();
  if (shareTokenFromPath()) {
    document.querySelector('#account-bar').hidden = true;
    document.querySelector('#signed-out').hidden = true;
  } else {
    showSignedOut('');
  }
  try {
    await api.signOut(token);
  } catch {
    // The device is already signed out. The server token can expire unused.
  }
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
  renderLibrary();
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
    renderLibrary();
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

function renderLibrary() {
  renderWorkouts(account.snapshot.workouts);
  renderHistory(account.snapshot.sessions);
  document.querySelector('#account-email').textContent = account.email;
}

function renderWorkouts(workouts) {
  const list = document.querySelector('#workout-list');
  list.replaceChildren();
  if (workouts.length === 0) {
    list.append(emptyNote('No workouts yet. Create one to use on the phone.'));
    return;
  }
  for (const group of groupWorkouts(workouts)) {
    if (group.section) {
      const heading = document.createElement('h3');
      heading.textContent = group.section;
      list.append(heading);
    }
    for (const workout of group.workouts) {
      list.append(workoutCard(workout));
    }
  }
}

function groupWorkouts(workouts) {
  const groups = [];
  const sectionIndex = new Map();
  for (const workout of workouts) {
    const section = typeof workout.section === 'string' ? workout.section.trim() : '';
    if (!section) {
      groups.push({ section: '', workouts: [workout] });
      continue;
    }
    if (!sectionIndex.has(section)) {
      sectionIndex.set(section, groups.length);
      groups.push({ section, workouts: [workout] });
    } else {
      groups[sectionIndex.get(section)].workouts.push(workout);
    }
  }
  return groups;
}

function workoutCard(workout) {
  const card = document.createElement('article');
  card.className = 'card';
  const title = document.createElement('h3');
  title.textContent = workout.name;
  const meta = document.createElement('p');
  meta.className = 'meta';
  const count = workout.exercises?.length ?? 0;
  const duration = formatDuration(estimatedDurationSeconds(workout.exercises || []));
  meta.textContent = `${exerciseCountLabel(count)} · ${duration}`;
  const lines = document.createElement('div');
  for (const exercise of workout.exercises || []) {
    const line = document.createElement('p');
    line.className = 'meta';
    line.textContent = exerciseLine(exercise);
    lines.append(line);
  }
  const actions = document.createElement('div');
  actions.className = 'workout-actions';
  const edit = document.createElement('button');
  edit.type = 'button';
  edit.className = 'ghost';
  edit.textContent = 'Edit';
  edit.addEventListener('click', () => openEditor(workout));
  const runButton = document.createElement('button');
  runButton.type = 'button';
  runButton.className = 'primary';
  runButton.textContent = 'Run';
  runButton.addEventListener('click', () => startWorkout(workout, sharingApp));
  const row = document.createElement('div');
  row.className = 'button-row';
  row.append(runButton, edit);
  actions.append(row, workoutShareButtons(workout, sharingApp));
  card.append(title, meta, lines, actions);
  return card;
}

function renderHistory(sessions) {
  const list = document.querySelector('#history-list');
  list.replaceChildren();
  const ordered = [...sessions].sort(
    (a, b) => Date.parse(b.completedAt) - Date.parse(a.completedAt),
  );
  if (ordered.length === 0) {
    list.append(emptyNote('No sessions yet.'));
    return;
  }
  for (const session of ordered) {
    list.append(historyCard(session));
  }
}

function historyCard(session) {
  const card = document.createElement('article');
  card.className = 'card';
  const title = document.createElement('h3');
  title.textContent = session.workoutName;
  const meta = document.createElement('p');
  meta.className = 'meta';
  const when = formatSessionDate(session.completedAt);
  const duration = formatDuration(session.durationSeconds);
  meta.textContent = `${when} · ${duration} · ${exerciseCountLabel(session.totalExercises)}`;
  card.append(title, meta);
  return card;
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

function formValues(form) {
  const data = new FormData(form);
  return {
    email: String(data.get('email') || '').trim(),
    password: String(data.get('password') || ''),
    displayName: String(data.get('displayName') || '').trim(),
  };
}

function exerciseCountLabel(count) {
  if (count === 1) {
    return '1 exercise';
  }
  return `${count} exercises`;
}

function emptyNote(text) {
  const note = document.createElement('p');
  note.className = 'empty';
  note.textContent = text;
  return note;
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
