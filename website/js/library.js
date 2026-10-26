import {
  estimatedWorkoutSeconds,
  formatDuration,
  formatSessionDate,
  workoutLines,
  workoutStations,
} from './snapshot.js';
import { workoutShareButtons } from './sharing.js';
import { startWorkout } from './workout_run.js';

export function renderLibrary(account, app) {
  renderWorkouts(account.snapshot.workouts, app);
  renderHistory(account.snapshot.sessions);
  document.querySelector('#account-email').textContent = account.email;
}

function renderWorkouts(workouts, app) {
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
      list.append(workoutCard(workout, app));
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

function workoutCard(workout, app) {
  const card = document.createElement('article');
  card.className = 'card';
  const title = document.createElement('h3');
  title.textContent = workout.name;
  const meta = document.createElement('p');
  meta.className = 'meta';
  const count = workoutStations(workout).length;
  const duration = formatDuration(estimatedWorkoutSeconds(workout));
  const circuits = (workout.blocks || []).filter((block) => block.type === 'circuit').length;
  const circuitText = circuits > 0 ? ` · ${circuits === 1 ? '1 circuit' : `${circuits} circuits`}` : '';
  meta.textContent = `${exerciseCountLabel(count)}${circuitText} · ${duration}`;
  const lines = document.createElement('div');
  for (const text of workoutLines(workout)) {
    const line = document.createElement('p');
    line.className = 'meta';
    line.textContent = text;
    lines.append(line);
  }
  const actions = document.createElement('div');
  actions.className = 'workout-actions';
  const edit = document.createElement('button');
  edit.type = 'button';
  edit.className = 'ghost';
  edit.textContent = 'Edit';
  edit.addEventListener('click', () => app.openEditor(workout));
  const runButton = document.createElement('button');
  runButton.type = 'button';
  runButton.className = 'primary';
  runButton.textContent = 'Run';
  runButton.addEventListener('click', () => startWorkout(workout, app));
  const row = document.createElement('div');
  row.className = 'button-row';
  row.append(runButton, edit);
  actions.append(row, workoutShareButtons(workout, app));
  card.append(title, meta, lines, actions);
  return card;
}

function renderHistory(sessions) {
  const list = document.querySelector('#history-list');
  list.replaceChildren();
  const ordered = [...sessions].sort(
    (left, right) => Date.parse(right.completedAt) - Date.parse(left.completedAt),
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
