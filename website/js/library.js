import { emptyState } from './empty_state.js';
import { exerciseList, workoutSummary } from './exercise_rows.js';
import { deleteHistorySession, groupLabel, renderHistory } from './history.js';
import { workoutShareButtons } from './sharing.js';
import { startWorkout } from './workout_run.js';

export function renderLibrary(account, app) {
  renderWorkouts(account.snapshot.workouts, app);
  renderHistory(account.snapshot.sessions, new Date(), (session) => {
    deleteHistorySession(app, session);
  });
  document.querySelector('#account-email').textContent = account.email;
}

function renderWorkouts(workouts, app) {
  const list = document.querySelector('#workout-list');
  list.replaceChildren();
  if (workouts.length === 0) {
    list.append(emptyState({
      icon: 'dumbbell',
      title: 'Create your first workout',
      text: 'Add your exercises once, then run them here or on your phone.',
      actions: [
        { label: 'Create workout', onClick: () => app.openEditor(null) },
        { label: 'Import a workout', style: 'ghost', onClick: () => document.querySelector('#open-import').click() },
      ],
    }));
    return;
  }
  for (const group of groupWorkouts(workouts)) {
    if (group.section) {
      list.append(groupLabel(group.section, group.workouts.length));
    }
    const grid = document.createElement('div');
    grid.className = 'workout-grid';
    for (const workout of group.workouts) {
      grid.append(workoutCard(workout, app));
    }
    list.append(grid);
  }
}

/// Workouts with the same section go together. Unsectioned workouts next to
/// each other share one group, so they sit in the same grid.
function groupWorkouts(workouts) {
  const groups = [];
  const sectionIndex = new Map();
  for (const workout of workouts) {
    const section = typeof workout.section === 'string' ? workout.section.trim() : '';
    const last = groups[groups.length - 1];
    if (!section && last && !last.section) {
      last.workouts.push(workout);
    } else if (!section) {
      groups.push({ section: '', workouts: [workout] });
    } else if (sectionIndex.has(section)) {
      groups[sectionIndex.get(section)].workouts.push(workout);
    } else {
      sectionIndex.set(section, groups.length);
      groups.push({ section, workouts: [workout] });
    }
  }
  return groups;
}

function workoutCard(workout, app) {
  const card = document.createElement('article');
  card.className = 'card workout-card';
  const title = document.createElement('h3');
  title.textContent = workout.name;
  const meta = document.createElement('p');
  meta.className = 'meta';
  meta.textContent = workoutSummary(workout);
  const actions = document.createElement('div');
  actions.className = 'button-row card-buttons';
  actions.append(
    actionButton('Run', 'primary', () => startWorkout(workout, app)),
    actionButton('Edit', 'ghost', () => app.openEditor(workout)),
    workoutShareButtons(workout, app),
  );
  card.append(title, meta, exerciseList(workout), actions);
  return card;
}

function actionButton(label, style, onClick) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = style;
  button.textContent = label;
  button.addEventListener('click', onClick);
  return button;
}
