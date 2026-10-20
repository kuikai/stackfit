import { dateTimeLocalValue, newId } from './snapshot.js';

export function installSession(app) {
  document.querySelector('#log-session').addEventListener('click', () => onLogSession(app));
  document.querySelector('#session-form').addEventListener('submit', (event) => {
    onSaveSession(event, app);
  });
}

function onLogSession(app) {
  app.clearBanner();
  const workouts = app.account.snapshot.workouts;
  if (workouts.length === 0) {
    app.showBanner('Create a workout before logging a session.');
    return;
  }
  fillSessionForm(workouts);
  document.querySelector('#library').hidden = true;
  app.closeWorkoutEditor();
  document.querySelector('#share-link-box').hidden = true;
  document.querySelector('#session-editor').hidden = false;
}

async function onSaveSession(event, app) {
  event.preventDefault();
  const workout = selectedWorkout(app);
  const duration = sessionDuration();
  if (!workout) {
    app.showBanner('Choose a workout.');
    return;
  }
  if (duration < 1) {
    app.showBanner('Enter how long the session took.');
    return;
  }
  const when = new Date(document.querySelector('#session-when').value);
  if (Number.isNaN(when.getTime())) {
    app.showBanner('Enter when the session happened.');
    return;
  }
  const snapshot = app.cloneSnapshot(app.account.snapshot);
  snapshot.sessions.push({
    id: newId(),
    workoutId: workout.id,
    workoutName: workout.name,
    completedAt: when.toISOString(),
    durationSeconds: duration,
    totalExercises: workout.exercises.length,
  });
  await app.persist(snapshot, 'Saved. The app shows this the next time it syncs.');
}

function fillSessionForm(workouts) {
  const select = document.querySelector('#session-workout');
  select.replaceChildren();
  for (const workout of workouts) {
    const option = document.createElement('option');
    option.value = workout.id;
    option.textContent = workout.name;
    select.append(option);
  }
  document.querySelector('#session-when').value = dateTimeLocalValue(new Date());
  document.querySelector('#session-minutes').value = '0';
  document.querySelector('#session-seconds').value = '0';
}

function selectedWorkout(app) {
  const id = document.querySelector('#session-workout').value;
  return app.account.snapshot.workouts.find((workout) => workout.id === id);
}

function sessionDuration() {
  const minutes = Number(document.querySelector('#session-minutes').value);
  const seconds = Number(document.querySelector('#session-seconds').value);
  if (!Number.isInteger(minutes) || !Number.isInteger(seconds) || seconds > 59) {
    return 0;
  }
  return minutes * 60 + seconds;
}
