const stepSizes = { rest: 15, 'circuit-rest': 15, work: 5 };
const optional = new Set(['reps']);
const zeroAllowed = new Set(['reps', 'rest', 'circuit-rest']);

/// One exercise card, or one circuit box with its stations, for the editor list.
export function blockNode(block, index, count) {
  if (block.type === 'circuit') {
    return circuitNode(block, index, count);
  }
  const section = document.createElement('section');
  section.className = 'block';
  section.dataset.kind = 'exercise';
  section.append(exerciseCard(block.exercise, index, count, false));
  return section;
}

/// Moves a number field up or down by its step. An optional field left at
/// its lowest value goes back to empty.
export function stepNumber(button) {
  const input = button.parentElement.querySelector('input');
  const size = Number(input.dataset.stepSize || 1);
  const current = input.value === '' ? 0 : Number(input.value) || 0;
  const minimum = Number(input.min || 0);
  const next = current + Number(button.dataset.step) * size;
  if (optional.has(input.dataset.field) && next < 1) {
    input.value = '';
    return;
  }
  input.value = String(Math.max(minimum, next));
}

function circuitNode(block, index, count) {
  const section = document.createElement('section');
  section.className = 'block circuit-box';
  section.dataset.kind = 'circuit';
  section.dataset.id = block.id;
  const stations = document.createElement('div');
  stations.className = 'stations';
  (block.exercises || []).forEach((exercise, stationIndex) => {
    stations.append(exerciseCard(exercise, stationIndex, block.exercises.length, true));
  });
  const numbers = document.createElement('div');
  numbers.className = 'number-row two';
  numbers.append(
    numberField('Rounds', 'circuit-rounds', block.rounds ?? 3),
    numberField('Rest between (s)', 'circuit-rest', block.restBetweenRoundsSeconds ?? 60),
  );
  const add = document.createElement('button');
  add.type = 'button';
  add.className = 'add-button';
  add.dataset.action = 'add-station';
  add.textContent = '+ Add station';
  section.append(circuitHeading(index, count), circuitNote(), numbers, stations, add);
  return section;
}

function circuitHeading(index, count) {
  const row = document.createElement('div');
  row.className = 'card-head';
  const heading = document.createElement('h3');
  heading.textContent = 'Circuit';
  row.append(heading, moveButtons(index, count, 'block-up', 'block-down', 'remove-block', 'circuit'));
  return row;
}

function circuitNote() {
  const note = document.createElement('p');
  note.className = 'meta';
  note.textContent = 'These exercises run in order, then repeat.';
  return note;
}

function exerciseCard(exercise, index, count, inCircuit) {
  const card = document.createElement('article');
  card.className = 'exercise';
  card.dataset.id = exercise.id;
  const head = document.createElement('div');
  head.className = 'card-head';
  const badge = document.createElement('span');
  badge.className = 'step-badge';
  badge.textContent = String(index + 1);
  const name = document.createElement('input');
  name.className = 'exercise-name';
  name.type = 'text';
  name.value = exercise.name;
  name.placeholder = inCircuit ? 'Station name' : 'Exercise name';
  name.setAttribute('aria-label', name.placeholder);
  head.append(badge, typeSwitch(exercise.type), moveButtons(index, count, 'up', 'down', 'remove', 'exercise'));
  const numbers = document.createElement('div');
  numbers.className = 'number-row';
  numbers.append(...typeFields(exercise, inCircuit));
  card.append(head, name, numbers);
  return card;
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
  button.dataset.type = type;
  button.textContent = label;
  button.setAttribute('aria-pressed', String(type === selected));
  return button;
}

function typeFields(exercise, inCircuit) {
  const restLabel = inCircuit ? 'Rest after (s)' : 'Rest (s)';
  if (exercise.type === 'timer') {
    return [
      numberField('Work (s)', 'work', exercise.workSeconds ?? 40),
      numberField(restLabel, 'rest', exercise.restSeconds ?? 15),
      numberField('Rounds', 'rounds', exercise.sets ?? (inCircuit ? 1 : 3)),
    ];
  }
  return [
    numberField('Sets', 'sets', exercise.sets ?? (inCircuit ? 1 : 3)),
    numberField('Reps', 'reps', exercise.reps ?? ''),
    numberField(restLabel, 'rest', exercise.restSeconds ?? (inCircuit ? 15 : 60)),
  ];
}

function numberField(labelText, field, value) {
  const wrap = document.createElement('div');
  wrap.className = 'field number-field';
  const label = document.createElement('span');
  label.textContent = labelText;
  const stepper = document.createElement('div');
  stepper.className = 'stepper';
  const input = document.createElement('input');
  input.className = field;
  input.dataset.field = field;
  input.dataset.stepSize = String(stepSizes[field] || 1);
  input.type = 'number';
  input.inputMode = 'numeric';
  input.min = zeroAllowed.has(field) ? '0' : '1';
  input.step = '1';
  input.value = value;
  input.setAttribute('aria-label', labelText);
  if (optional.has(field)) {
    input.placeholder = '–';
  }
  stepper.append(stepButton(-1, labelText), input, stepButton(1, labelText));
  wrap.append(label, stepper);
  return wrap;
}

function stepButton(direction, labelText) {
  const button = document.createElement('button');
  button.type = 'button';
  button.dataset.step = String(direction);
  button.textContent = direction < 0 ? '−' : '+';
  button.setAttribute('aria-label', `${direction < 0 ? 'Less' : 'More'} ${labelText.toLowerCase()}`);
  return button;
}

function moveButtons(index, count, up, down, remove, noun) {
  const group = document.createElement('div');
  group.className = 'icon-buttons';
  group.append(
    iconButton('↑', up, `Move ${noun} up`, index === 0),
    iconButton('↓', down, `Move ${noun} down`, index === count - 1),
    iconButton('✕', remove, `Remove ${noun}`, false),
  );
  return group;
}

function iconButton(symbol, action, label, disabled) {
  const button = document.createElement('button');
  button.type = 'button';
  button.className = 'icon-button';
  button.dataset.action = action;
  button.textContent = symbol;
  button.title = label;
  button.setAttribute('aria-label', label);
  button.disabled = disabled;
  return button;
}
