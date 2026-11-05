import { hideAppearance } from './appearance.js';
import { appStoreUrl } from './app_links.js';
import { exerciseList, workoutSummary } from './exercise_rows.js';
import { historyRow, shortMinutes } from './history.js';

export async function openPublicShare(token, app) {
  app.clearBanner();
  app.localWorkout = null;
  showSharePage();
  if (app.account.token) {
    await app.loadAccountData().catch(() => app.clearAccount());
  }
  document.querySelector('#share-home').hidden = !app.account.token;
  try {
    fillShareView(await app.api.readShare(token));
  } catch (error) {
    fillShareError(error.message);
  }
}

export function showLocalWorkout(workout, app) {
  app.localWorkout = workout;
  showSharePage();
  document.querySelector('#share-home').hidden = !app.account.token;
  document.querySelector('#share-copy').hidden = true;
  fillShareView({
    kind: 'workout',
    name: workout.name,
    exercises: workout.exercises,
    blocks: workout.blocks,
  });
  document.querySelector('#share-kicker').textContent = 'From a file';
}

function showSharePage() {
  const getApp = document.querySelector('#get-app');
  getApp.hidden = !appStoreUrl;
  getApp.href = appStoreUrl || '#';
  document.querySelector('#signed-in').hidden = true;
  document.querySelector('#signed-out').hidden = true;
  document.querySelector('#account-bar').hidden = true;
  hideAppearance();
  document.querySelector('#share-view').hidden = false;
  document.querySelector('#share-copy').hidden = false;
}

function fillShareView(payload) {
  document.querySelector('#share-error').hidden = true;
  document.querySelector('#share-content').hidden = false;
  const progress = payload.kind === 'progress';
  document.querySelector('#share-kicker').textContent = progress ? 'Shared progress' : 'Shared workout';
  document.querySelector('#share-title').textContent = progress ? 'Training progress' : payload.name;
  document.title = `${progress ? 'Training progress' : payload.name} · StackFit`;
  document.querySelector('#share-add').hidden = progress;
  document.querySelector('#share-note').textContent = progress
    ? 'Only the sessions that were shared. Nothing is added to your history.'
    : 'Adding makes your own copy. Later edits on either side stay separate.';
  const body = document.querySelector('#share-body');
  const summary = document.querySelector('#share-summary');
  if (progress) {
    const sessions = [...payload.sessions].sort(
      (a, b) => Date.parse(b.completedAt) - Date.parse(a.completedAt),
    );
    const minutes = shortMinutes(sessions.reduce((total, session) => total + (session.durationSeconds || 0), 0));
    summary.textContent = `${sessions.length === 1 ? '1 session' : `${sessions.length} sessions`} · ${minutes} in total`;
    body.replaceChildren(...sessions.map((session) => historyRow(session)));
    return;
  }
  summary.textContent = workoutSummary(payload);
  body.replaceChildren(exerciseList(payload));
}

function fillShareError(message) {
  document.querySelector('#share-content').hidden = true;
  document.querySelector('#share-error').hidden = false;
  document.querySelector('#share-error-text').textContent = message;
}
