import { newId } from './snapshot.js';

let draftId = '';
let createdAt = '';
let draftSection = '';

export function openWorkoutEditor(workout) {
  const editor = document.querySelector('#editor');
  const title = document.querySelector('#editor-title');
  const name = document.querySelector('#workout-name');
  const remove = document.querySelector('#delete-workout');
  draftId = workout?.id || newId();
  createdAt = workout?.createdAt || new Date().toISOString();
  draftSection = typeof workout?.section === 'string' ? workout.section : '';
  title.textContent = workout ? 'Edit workout' : 'Create workout';
  name.value = workout?.name || '';
  remove.hidden = !workout;
  renderExercises(workout?.exercises?.length ? workout.exercises : [blankExercise()]);
  editor.hidden = false;
}

export function closeWorkoutEditor() {
  document.querySelector('#editor').hidden = true;
}

export function readWorkoutDraft() {
  const workout = {
    id: draftId,
    name: document.querySelector('#workout-name').value.trim(),
    exercises: readExercises(),
    createdAt,
    updatedAt: new Date().toISOString(),
  };
  const section = draftSection.trim();
  if (section) {
    workout.section = section;
  }
  return workout;
}

export function workoutError(workout) {
  if (!workout.name) {
    return 'Enter a workout name.';
  }
  if (workout.exercises.length === 0) {
    return 'Add at least one exercise.';
  }
  for (const exercise of workout.exercises) {
    const error = exerciseError(exercise);
    if (error) {
      return error;
    }
  }
  return null;
}

export function bindExerciseActions() {
  document.querySelector('#add-exercise').addEventListener('click', () => {
    renderExercises([...readExercises(), blankExercise()]);
  });
  document.querySelector('#exercise-list').addEventListener('click', onExerciseClick);
}

function onExerciseClick(event) {
  const index = cardIndex(event.target);
  if (index < 0) {
    return;
  }
  const type = event.target.closest('[data-type]')?.dataset.type;
  const exercises = readExercises();
  if (type) {
    exercises[index] = withType(exercises[index], type);
    renderExercises(exercises);
    return;
  }
  const action = event.target.closest('[data-action]')?.dataset.action;
  if (action == null) {
    return;
  }
  if (action === 'remove') {
    exercises.splice(index, 1);
  } else if (action === 'up' && index > 0) {
    [exercises[index - 1], exercises[index]] = [exercises[index], exercises[index - 1]];
  } else if (action === 'down' && index < exercises.length - 1) {
    [exercises[index + 1], exercises[index]] = [exercises[index], exercises[index + 1]];
  } else {
    return;
  }
  renderExercises(exercises);
}

function renderExercises(exercises) {
  const list = document.querySelector('#exercise-list');
  list.replaceChildren();
  exercises.forEach((exercise, index) => {
    list.append(exerciseCard(exercise, index, exercises.length));
  });
}

function exerciseCard(exercise, index, count) {
  const card = document.createElement('article');
  card.className = 'exercise';
  card.dataset.id = exercise.id;
  card.append(
    cardHeading(index),
    typeSwitch(exercise.type),
    labeledInput('Name', 'exercise-name', exercise.name, 'text'),
    ...typeFields(exercise),
    cardButtons(index, count),
  );
  return card;
}

function cardHeading(index) {
  const heading = document.createElement('h3');
  heading.textContent = `Exercise ${index + 1}`;
  return heading;
}

function typeSwitch(type) {
  const group = document.createElement('div');
  group.className = 'segment';
  group.append(typeButton('sets', 'Sets', type), typeButton('timer', 'Timer', type));
  return group;
}

function typeButton(type, label, selected) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'ghost';
  button.dataset.type = type;
  button.textContent = label;
  button.setAttribute('aria-pressed', String(type === selected));
  return button;
}

function typeFields(exercise) {
  if (exercise.type === 'timer') {
    return [
      labeledInput('Work (seconds)', 'work', exercise.workSeconds ?? 45, 'number'),
      labeledInput('Rest (seconds)', 'rest', exercise.restSeconds ?? 15, 'number'),
      labeledInput('Sets / rounds', 'rounds', exercise.sets ?? 3, 'number'),
    ];
  }
  return [
    labeledInput('Sets', 'sets', exercise.sets ?? 3, 'number'),
    labeledInput('Reps (optional)', 'reps', exercise.reps ?? '', 'number'),
    labeledInput('Rest between sets (seconds)', 'rest', exercise.restSeconds ?? 60, 'number'),
  ];
}

function labeledInput(labelText, className, value, type) {
  const label = document.createElement('label');
  label.className = 'field';
  const span = document.createElement('span');
  span.textContent = labelText;
  const input = document.createElement('input');
  input.className = className;
  input.type = type;
  input.value = value;
  if (type === 'number') {
    input.min = className === 'reps' || className === 'rest' ? '0' : '1';
    input.step = '1';
  }
  label.append(span, input);
  return label;
}

function cardButtons(index, count) {
  const row = document.createElement('div');
  row.className = 'card-actions';
  row.append(
    actionButton('Up', 'up', index === 0),
    actionButton('Down', 'down', index === count - 1),
    actionButton('Remove', 'remove', false),
  );
  return row;
}

function actionButton(label, action, disabled) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'ghost';
  button.dataset.action = action;
  button.textContent = label;
  button.disabled = disabled;
  return button;
}

function readExercises() {
  return [...document.querySelectorAll('.exercise')].map(readExercise);
}

function readExercise(card) {
  const type = card.querySelector('[aria-pressed="true"]')?.dataset.type || 'sets';
  const name = card.querySelector('.exercise-name').value.trim();
  const id = card.dataset.id;
  if (type === 'timer') {
    return timerExercise(card, id, name);
  }
  return setsExercise(card, id, name);
}

function timerExercise(card, id, name) {
  return {
    id,
    name,
    type: 'timer',
    workSeconds: numberFrom(card, '.work'),
    restSeconds: numberFrom(card, '.rest'),
    sets: numberFrom(card, '.rounds'),
    reps: null,
  };
}

function setsExercise(card, id, name) {
  const repsRaw = card.querySelector('.reps').value.trim();
  return {
    id,
    name,
    type: 'sets',
    workSeconds: null,
    restSeconds: numberFrom(card, '.rest'),
    sets: numberFrom(card, '.sets'),
    reps: repsRaw === '' ? null : Number(repsRaw),
  };
}

function exerciseError(exercise) {
  if (!exercise.name) {
    return 'Enter an exercise name.';
  }
  if (exercise.type === 'timer') {
    return timerError(exercise);
  }
  return setsError(exercise);
}

function timerError(exercise) {
  if (!Number.isInteger(exercise.workSeconds) || exercise.workSeconds < 1) {
    return 'Work time must be at least 1 second.';
  }
  if (!Number.isInteger(exercise.restSeconds) || exercise.restSeconds < 0) {
    return 'Enter a valid rest time.';
  }
  if (!Number.isInteger(exercise.sets) || exercise.sets < 1) {
    return 'Sets must be at least 1.';
  }
  return null;
}

function setsError(exercise) {
  if (!Number.isInteger(exercise.sets) || exercise.sets < 1) {
    return 'Sets must be at least 1.';
  }
  if (!Number.isInteger(exercise.restSeconds) || exercise.restSeconds < 0) {
    return 'Enter a valid rest time.';
  }
  if (exercise.reps != null && (!Number.isInteger(exercise.reps) || exercise.reps < 1)) {
    return 'Reps must be a positive number.';
  }
  return null;
}

function withType(exercise, type) {
  return {
    ...exercise,
    type,
    workSeconds: exercise.workSeconds ?? 45,
    restSeconds: exercise.restSeconds ?? (type === 'timer' ? 15 : 60),
    sets: exercise.sets ?? 3,
  };
}

function blankExercise() {
  return {
    id: newId(),
    name: '',
    type: 'sets',
    sets: 3,
    reps: 8,
    restSeconds: 60,
    workSeconds: null,
  };
}

function numberFrom(card, selector) {
  return Number(card.querySelector(selector).value);
}

function cardIndex(target) {
  const card = target.closest('.exercise');
  if (!card) {
    return -1;
  }
  return [...document.querySelectorAll('.exercise')].indexOf(card);
}
