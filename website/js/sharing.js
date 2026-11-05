import { parseRoutineText, routineError } from './routine_check.js';
import { showLocalWorkout } from './share_page.js';
import { formatDuration, formatSessionDate, newId } from './snapshot.js';

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

export function workoutFromShare(share) {
  const now = new Date().toISOString();
  const blocks = copyShareBlocks(share);
  const exercises = blocks
    ? blocks.flatMap((block) => (block.type === 'circuit' ? block.exercises : [block.exercise]))
    : (share.exercises || []).map(copyExercise);
  const workout = {
    id: newId(),
    name: share.name,
    createdAt: now,
    updatedAt: now,
    exercises,
  };
  if (blocks) {
    workout.blocks = blocks;
  }
  return workout;
}

function copyShareBlocks(share) {
  if (!Array.isArray(share.blocks) || share.blocks.length === 0) {
    return null;
  }
  return share.blocks.map((block) => {
    if (block.type === 'circuit') {
      return {
        type: 'circuit',
        id: newId(),
        rounds: block.rounds,
        restBetweenRoundsSeconds: block.restBetweenRoundsSeconds ?? 0,
        exercises: (block.exercises || []).map(copyExercise),
      };
    }
    return { type: 'exercise', exercise: copyExercise(block.exercise) };
  });
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
    app.showBanner('Finish a workout before sharing progress.');
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
  button.textContent = 'Unshare';
  button.title = 'Turn off this link';
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
