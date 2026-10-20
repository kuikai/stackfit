import {
  estimatedDurationSeconds,
  exerciseLine,
  formatDuration,
  formatSessionDate,
  newId,
} from './snapshot.js';

const phoneNote = 'The app shows it the next time it syncs.';

export function shareTokenFromPath() {
  return tokenIn(window.location.pathname);
}

export function shareTokenFromText(value) {
  return tokenIn(value.trim());
}

export function installSharing(app) {
  document.querySelector('#receive-link-form').addEventListener('submit', (event) => {
    event.preventDefault();
    const token = shareTokenFromText(document.querySelector('#receive-link').value);
    if (!token) {
      app.showBanner('Paste a StackFit workout link.');
      return;
    }
    window.location.assign(`/s/${token}`);
  });
  document.querySelector('#receive-file').addEventListener('change', (event) => {
    onRoutineFile(event, app);
  });
  document.querySelector('#share-add').addEventListener('click', () => addSharedWorkout(app));
  document.querySelector('#share-copy').addEventListener('click', () => copyPageLink(app));
  document.querySelector('#share-link-copy').addEventListener('click', () => copyShownLink(app));
  document.querySelector('#share-link-off').addEventListener('click', () => turnOffShownLink(app));
  document.querySelector('#share-progress').addEventListener('click', () => openProgressPicker(app));
  document.querySelector('#progress-cancel').addEventListener('click', () => {
    document.querySelector('#progress-picker').hidden = true;
    app.showLibrary();
  });
  document.querySelector('#progress-create').addEventListener('click', () => createProgressLink(app));
}

export function workoutShareButtons(workout, app) {
  const row = document.createElement('div');
  row.className = 'card-actions';
  const share = document.createElement('button');
  share.type = 'button';
  share.className = 'ghost';
  share.textContent = 'Share';
  share.addEventListener('click', () => shareWorkout(workout, app));
  row.append(share);
  const existing = linkFor(app, 'workout', workout.id);
  if (existing) {
    row.append(turnOffButton(existing.token, app));
  }
  return row;
}

export async function openPublicShare(token, app) {
  app.clearBanner();
  app.localWorkout = null;
  document.querySelector('#signed-in').hidden = true;
  document.querySelector('#signed-out').hidden = true;
  document.querySelector('#share-view').hidden = false;
  if (app.account.token) {
    document.querySelector('#account-bar').hidden = false;
    document.querySelector('#account-email').textContent = app.account.email;
    await app.loadAccountData().catch(() => {
      app.clearAccount();
      document.querySelector('#account-bar').hidden = true;
    });
  }
  try {
    fillShareView(await app.api.readShare(token));
  } catch (error) {
    fillShareError(error.message);
  }
}

export function showLocalWorkout(workout, app) {
  app.localWorkout = workout;
  document.querySelector('#signed-in').hidden = true;
  document.querySelector('#signed-out').hidden = true;
  document.querySelector('#share-view').hidden = false;
  fillShareView({ kind: 'workout', name: workout.name, exercises: workout.exercises });
}

export function workoutFromShare(share) {
  const now = new Date().toISOString();
  return {
    id: newId(),
    name: share.name,
    createdAt: now,
    updatedAt: now,
    exercises: (share.exercises || []).map(copyExercise),
  };
}

export function parseRoutineText(raw) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { error: 'That file is not a StackFit routine.' };
  }
  const error = routineError(parsed);
  if (error) {
    return { error };
  }
  return {
    workout: {
      name: String(parsed.name).trim(),
      exercises: parsed.exercises,
    },
  };
}

export function routineError(workout) {
  if (!workout || typeof workout.name !== 'string' || !workout.name.trim()) {
    return 'A routine needs a name.';
  }
  if (!Array.isArray(workout.exercises) || workout.exercises.length === 0) {
    return 'A routine needs at least one exercise.';
  }
  for (const exercise of workout.exercises) {
    const error = exerciseError(exercise);
    if (error) {
      return error;
    }
  }
  return '';
}

function tokenIn(value) {
  const match = String(value).trim().match(/(?:^|\/s\/)([a-f0-9]{16,64})(?:[/?#].*)?$/i);
  return match ? match[1].toLowerCase() : '';
}

function copyExercise(exercise) {
  return {
    id: newId(),
    name: exercise.name,
    type: exercise.type,
    workSeconds: exercise.workSeconds ?? null,
    restSeconds: exercise.restSeconds ?? null,
    sets: exercise.sets ?? null,
    reps: exercise.reps ?? null,
  };
}

async function onRoutineFile(event, app) {
  const file = event.target.files?.[0];
  event.target.value = '';
  if (!file) {
    return;
  }
  let text = '';
  try {
    text = await file.text();
  } catch {
    app.showBanner('Could not read that file.');
    return;
  }
  const parsed = parseRoutineText(text);
  if (parsed.error) {
    app.showBanner(parsed.error);
    return;
  }
  if (!app.account.token) {
    sessionStorage.setItem('stackfit.pendingRoutine', JSON.stringify(parsed.workout));
    app.promptSignIn('Sign in to add this routine.');
    return;
  }
  showLocalWorkout(parsed.workout, app);
}

async function addSharedWorkout(app) {
  const local = app.localWorkout;
  const token = shareTokenFromPath();
  if (!app.account.token) {
    rememberAndSignIn(app, local, token);
    return;
  }
  const source = local || await app.api.readShare(token);
  const error = routineError(source);
  if (error) {
    app.showBanner(error);
    return;
  }
  try {
    await app.loadAccountData();
  } catch (loadError) {
    app.clearAccount();
    rememberAndSignIn(app, local, token);
    return;
  }
  const snapshot = app.cloneSnapshot(app.account.snapshot);
  snapshot.workouts.push(workoutFromShare(source));
  app.localWorkout = null;
  await app.persist(snapshot, `Added to your account. ${phoneNote}`);
  if (window.location.pathname.startsWith('/s/')) {
    window.history.pushState({}, '', '/');
  }
}

function rememberAndSignIn(app, local, token) {
  if (local) {
    sessionStorage.setItem('stackfit.pendingRoutine', JSON.stringify(local));
  } else if (token) {
    sessionStorage.setItem('stackfit.returnShare', token);
  }
  app.promptSignIn('Sign in to add this workout. You will come back to this page.');
}

async function shareWorkout(workout, app) {
  app.clearBanner();
  try {
    const saved = await app.api.createShare(app.account.token, {
      kind: 'workout',
      workoutId: workout.id,
    });
    await app.loadShares();
    app.renderLibrary();
    showLinkBox(saved.token, 'Link copied. Anyone with it can read this workout and add a copy.');
    await copyText(`${window.location.origin}/s/${saved.token}`);
  } catch (error) {
    app.showBanner(error.message);
  }
}

function openProgressPicker(app) {
  const sessions = [...(app.account.snapshot.sessions || [])];
  if (sessions.length === 0) {
    app.showBanner('Log a session before sharing progress.');
    return;
  }
  sessions.sort((a, b) => Date.parse(b.completedAt) - Date.parse(a.completedAt));
  const list = document.querySelector('#progress-choices');
  list.replaceChildren();
  for (const session of sessions) {
    list.append(progressChoice(session));
  }
  document.querySelector('#library').hidden = true;
  document.querySelector('#progress-picker').hidden = false;
}

async function createProgressLink(app) {
  const sessionIds = [...document.querySelectorAll('#progress-choices input:checked')].map(
    (input) => input.value,
  );
  if (sessionIds.length === 0) {
    app.showBanner('Choose at least one session.');
    return;
  }
  try {
    const saved = await app.api.createShare(app.account.token, {
      kind: 'progress',
      sessionIds,
    });
    await app.loadShares();
    app.showLibrary();
    showLinkBox(saved.token, 'Link copied. It shows those sessions, not your email.');
    await copyText(`${window.location.origin}/s/${saved.token}`);
  } catch (error) {
    app.showBanner(error.message);
  }
}

function progressChoice(session) {
  const label = document.createElement('label');
  label.className = 'check';
  const input = document.createElement('input');
  input.type = 'checkbox';
  input.checked = true;
  input.value = session.id;
  const text = document.createElement('span');
  text.textContent = `${session.workoutName} · ${formatSessionDate(session.completedAt)} · ${formatDuration(session.durationSeconds)}`;
  label.append(input, text);
  return label;
}

function fillShareView(payload) {
  document.querySelector('#share-view').hidden = false;
  document.querySelector('#share-error').hidden = true;
  document.querySelector('#share-content').hidden = false;
  const progress = payload.kind === 'progress';
  document.querySelector('#share-kicker').textContent = progress
    ? 'Progress summary'
    : 'Shared workout';
  document.querySelector('#share-title').textContent = progress
    ? 'Training progress'
    : payload.name;
  document.querySelector('#share-add').hidden = progress;
  document.querySelector('#share-note').textContent = progress
    ? 'This is only the sessions that were shared. It is not added to your history.'
    : 'Adding this makes a copy on your account. Later edits stay where they were made.';
  const summary = document.querySelector('#share-summary');
  const body = document.querySelector('#share-body');
  body.replaceChildren();
  if (progress) {
    const sessionCount = payload.sessions.length;
    summary.textContent = sessionCount === 1 ? '1 session' : `${sessionCount} sessions`;
    for (const session of payload.sessions) {
      body.append(line(
        `${session.workoutName} · ${formatSessionDate(session.completedAt)} · ${formatDuration(session.durationSeconds)}`,
      ));
    }
    return;
  }
  const count = payload.exercises.length;
  const duration = formatDuration(estimatedDurationSeconds(payload.exercises));
  summary.textContent = `${count === 1 ? '1 exercise' : `${count} exercises`} · ${duration}`;
  for (const exercise of payload.exercises) {
    body.append(line(exerciseLine(exercise)));
  }
}

function fillShareError(message) {
  document.querySelector('#share-content').hidden = true;
  const error = document.querySelector('#share-error');
  error.hidden = false;
  error.textContent = message;
}

function line(text) {
  const row = document.createElement('p');
  row.className = 'meta';
  row.textContent = text;
  return row;
}

function showLinkBox(token, label) {
  const box = document.querySelector('#share-link-box');
  box.hidden = false;
  box.dataset.token = token;
  document.querySelector('#share-link-label').textContent = label;
  document.querySelector('#share-link-input').value = `${window.location.origin}/s/${token}`;
}

async function copyPageLink(app) {
  const copied = await copyText(window.location.href);
  app.showBanner(copied ? 'Link copied.' : 'Copy the address from the browser.', copied ? 'ok' : 'error');
}

async function copyShownLink(app) {
  const value = document.querySelector('#share-link-input').value;
  const copied = await copyText(value);
  app.showBanner(copied ? 'Link copied.' : 'Copy the link from the box.', copied ? 'ok' : 'error');
}

async function turnOffShownLink(app) {
  const token = document.querySelector('#share-link-box').dataset.token;
  await disableToken(token, app);
  document.querySelector('#share-link-box').hidden = true;
}

function turnOffButton(token, app) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'text';
  button.textContent = 'Turn off link';
  button.addEventListener('click', () => disableToken(token, app));
  return button;
}

async function disableToken(token, app) {
  try {
    await app.api.disableShare(app.account.token, token);
    await app.loadShares();
    app.renderLibrary();
    app.showBanner('Link turned off. Copies already added stay on those accounts.', 'ok');
  } catch (error) {
    app.showBanner(error.message);
  }
}

function linkFor(app, kind, sourceId) {
  return (app.account.shares || []).find(
    (share) => share.kind === kind && share.sourceId === sourceId && share.enabled !== false,
  );
}

async function copyText(value) {
  try {
    await navigator.clipboard.writeText(value);
    return true;
  } catch {
    return false;
  }
}

function exerciseError(exercise) {
  if (!exercise || typeof exercise.name !== 'string' || !exercise.name.trim()) {
    return 'Each exercise needs a name.';
  }
  if (exercise.type === 'timer') {
    return numberError(exercise.workSeconds, 1, 'Work time must be at least 1 second.')
      || numberError(exercise.restSeconds, 0, 'Enter a valid rest time.')
      || numberError(exercise.sets, 1, 'Sets must be at least 1.');
  }
  if (exercise.type !== 'sets') {
    return 'Each exercise must be timer or sets.';
  }
  const reps = exercise.reps;
  if (reps != null && (!Number.isInteger(reps) || reps < 1)) {
    return 'Reps must be a positive number.';
  }
  return numberError(exercise.sets, 1, 'Sets must be at least 1.')
    || numberError(exercise.restSeconds, 0, 'Enter a valid rest time.');
}

function numberError(value, minimum, message) {
  if (!Number.isInteger(value) || value < minimum) {
    return message;
  }
  return '';
}
