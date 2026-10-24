import { newId } from './snapshot.js';

export function bindBlockEditor() {
  document.querySelector('#add-exercise').addEventListener('click', () => {
    renderBlocks([...readBlocks(), exerciseBlock(blankExercise())]);
  });
  document.querySelector('#add-circuit').addEventListener('click', () => {
    renderBlocks([...readBlocks(), blankCircuit()]);
  });
  document.querySelector('#exercise-list').addEventListener('click', onListClick);
}

export function renderBlocks(blocks) {
  const list = document.querySelector('#exercise-list');
  list.replaceChildren();
  blocks.forEach((block, index) => {
    list.append(blockNode(block, index, blocks.length));
  });
}

export function readBlocks() {
  return [...document.querySelectorAll('#exercise-list > .block')].map(readBlock);
}

export function stationsFromBlocks(blocks) {
  return blocks.flatMap((block) => blockStations(block));
}

export function blocksProblem(blocks) {
  if (stationsFromBlocks(blocks).length === 0) {
    return 'Add at least one exercise.';
  }
  for (const block of blocks) {
    const problem = blockProblem(block);
    if (problem) {
      return problem;
    }
  }
  return '';
}

function onListClick(event) {
  const type = event.target.closest('[data-type]')?.dataset.type;
  const action = event.target.closest('[data-action]')?.dataset.action;
  if (!type && !action) {
    return;
  }
  const blocks = readBlocks();
  const place = placeOf(event.target);
  if (place.blockIndex < 0) {
    return;
  }
  if (type) {
    changeType(blocks, place, type);
    renderBlocks(blocks);
    return;
  }
  if (action === 'add-station') {
    blocks[place.blockIndex].exercises.push(blankStation());
    renderBlocks(blocks);
    return;
  }
  if (action === 'block-up' || action === 'block-down' || action === 'remove-block') {
    moveBlock(blocks, place.blockIndex, action);
    renderBlocks(blocks);
    return;
  }
  moveStation(blocks, place, action);
  renderBlocks(blocks);
}

function changeType(blocks, place, type) {
  const exercise = exerciseAt(blocks, place);
  if (!exercise) {
    return;
  }
  const next = withType(exercise, type);
  writeExercise(blocks, place, next);
}

function moveBlock(blocks, index, action) {
  if (action === 'remove-block') {
    blocks.splice(index, 1);
    return;
  }
  const next = action === 'block-up' ? index - 1 : index + 1;
  if (next < 0 || next >= blocks.length) {
    return;
  }
  [blocks[index], blocks[next]] = [blocks[next], blocks[index]];
}

function moveStation(blocks, place, action) {
  const block = blocks[place.blockIndex];
  const stations = blockStations(block);
  if (action === 'remove') {
    stations.splice(place.stationIndex, 1);
    writeStations(block, stations);
    if (block.type !== 'circuit' && stations.length === 0) {
      blocks.splice(place.blockIndex, 1);
    }
    return;
  }
  const next = action === 'up' ? place.stationIndex - 1 : place.stationIndex + 1;
  if (action !== 'up' && action !== 'down') {
    return;
  }
  if (block.type !== 'circuit') {
    moveBlock(blocks, place.blockIndex, action === 'up' ? 'block-up' : 'block-down');
    return;
  }
  if (next < 0 || next >= stations.length) {
    return;
  }
  [stations[place.stationIndex], stations[next]] = [stations[next], stations[place.stationIndex]];
  writeStations(block, stations);
}

function blockNode(block, index, count) {
  if (block.type === 'circuit') {
    return circuitNode(block, index, count);
  }
  const section = document.createElement('section');
  section.className = 'block';
  section.dataset.kind = 'exercise';
  section.append(exerciseCard(block.exercise, index, count, false));
  return section;
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
  section.append(
    circuitHeading(index, count),
    circuitNote(),
    labeledInput('Rounds', 'circuit-rounds', block.rounds ?? 3, 'number'),
    labeledInput('Rest between rounds (seconds)', 'circuit-rest', block.restBetweenRoundsSeconds ?? 60, 'number'),
    stations,
    actionButton('Add station', 'add-station', false),
  );
  return section;
}

function circuitHeading(index, count) {
  const row = document.createElement('div');
  row.className = 'circuit-head';
  const heading = document.createElement('h3');
  heading.textContent = 'Circuit';
  row.append(
    heading,
    actionButton('Up', 'block-up', index === 0),
    actionButton('Down', 'block-down', index === count - 1),
    actionButton('Remove', 'remove-block', false),
  );
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
  card.append(
    cardHeading(index, inCircuit),
    typeSwitch(exercise.type),
    labeledInput('Name', 'exercise-name', exercise.name, 'text'),
    ...typeFields(exercise, inCircuit),
    cardButtons(index, count),
  );
  return card;
}

function cardHeading(index, inCircuit) {
  const heading = document.createElement('h3');
  heading.textContent = inCircuit ? `Station ${index + 1}` : `Exercise ${index + 1}`;
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

function typeFields(exercise, inCircuit) {
  const restLabel = inCircuit ? 'Rest before next station (seconds)' : 'Rest (seconds)';
  if (exercise.type === 'timer') {
    return [
      labeledInput('Work (seconds)', 'work', exercise.workSeconds ?? 40, 'number'),
      labeledInput(restLabel, 'rest', exercise.restSeconds ?? 15, 'number'),
      labeledInput('Sets / rounds', 'rounds', exercise.sets ?? (inCircuit ? 1 : 3), 'number'),
    ];
  }
  const setsRest = inCircuit ? restLabel : 'Rest between sets (seconds)';
  return [
    labeledInput('Sets', 'sets', exercise.sets ?? (inCircuit ? 1 : 3), 'number'),
    labeledInput('Reps (optional)', 'reps', exercise.reps ?? '', 'number'),
    labeledInput(setsRest, 'rest', exercise.restSeconds ?? (inCircuit ? 15 : 60), 'number'),
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
    input.min = className === 'reps' || className === 'rest' || className === 'circuit-rest' ? '0' : '1';
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

function readBlock(block) {
  if (block.dataset.kind === 'circuit') {
    return {
      type: 'circuit',
      id: block.dataset.id,
      rounds: numberIn(block, '.circuit-rounds'),
      restBetweenRoundsSeconds: numberIn(block, '.circuit-rest'),
      exercises: [...block.querySelectorAll('.stations .exercise')].map(readExercise),
    };
  }
  return { type: 'exercise', exercise: readExercise(block.querySelector('.exercise')) };
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
    workSeconds: numberIn(card, '.work'),
    restSeconds: numberIn(card, '.rest'),
    sets: numberIn(card, '.rounds'),
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
    restSeconds: numberIn(card, '.rest'),
    sets: numberIn(card, '.sets'),
    reps: repsRaw === '' ? null : Number(repsRaw),
  };
}

function blockProblem(block) {
  if (block.type === 'circuit') {
    if (!Number.isInteger(block.rounds) || block.rounds < 1) {
      return 'Circuit rounds must be at least 1.';
    }
    if (!Number.isInteger(block.restBetweenRoundsSeconds) || block.restBetweenRoundsSeconds < 0) {
      return 'Enter a valid rest between rounds.';
    }
    if (!block.exercises.length) {
      return 'Add at least one exercise to the circuit.';
    }
  }
  for (const exercise of blockStations(block)) {
    const problem = exerciseProblem(exercise);
    if (problem) {
      return problem;
    }
  }
  return '';
}

function exerciseProblem(exercise) {
  if (!exercise.name) {
    return 'Enter an exercise name.';
  }
  if (exercise.type === 'timer') {
    return timerProblem(exercise);
  }
  return setsProblem(exercise);
}

function timerProblem(exercise) {
  if (!Number.isInteger(exercise.workSeconds) || exercise.workSeconds < 1) {
    return 'Work time must be at least 1 second.';
  }
  if (!Number.isInteger(exercise.restSeconds) || exercise.restSeconds < 0) {
    return 'Enter a valid rest time.';
  }
  if (!Number.isInteger(exercise.sets) || exercise.sets < 1) {
    return 'Sets must be at least 1.';
  }
  return '';
}

function setsProblem(exercise) {
  if (!Number.isInteger(exercise.sets) || exercise.sets < 1) {
    return 'Sets must be at least 1.';
  }
  if (!Number.isInteger(exercise.restSeconds) || exercise.restSeconds < 0) {
    return 'Enter a valid rest time.';
  }
  if (exercise.reps != null && (!Number.isInteger(exercise.reps) || exercise.reps < 1)) {
    return 'Reps must be a positive number.';
  }
  return '';
}

function withType(exercise, type) {
  return {
    ...exercise,
    type,
    workSeconds: exercise.workSeconds ?? 40,
    restSeconds: exercise.restSeconds ?? (type === 'timer' ? 15 : 60),
    sets: exercise.sets ?? 1,
  };
}

function writeExercise(blocks, place, exercise) {
  const block = blocks[place.blockIndex];
  if (block.type === 'circuit') {
    block.exercises[place.stationIndex] = exercise;
    return;
  }
  block.exercise = exercise;
}

function writeStations(block, stations) {
  if (block.type === 'circuit') {
    block.exercises = stations;
    return;
  }
  block.exercise = stations[0];
}

function exerciseAt(blocks, place) {
  return blockStations(blocks[place.blockIndex])[place.stationIndex];
}

function blockStations(block) {
  if (block.type === 'circuit') {
    return block.exercises || [];
  }
  return block.exercise ? [block.exercise] : [];
}

function placeOf(target) {
  const block = target.closest('.block');
  const blocks = [...document.querySelectorAll('#exercise-list > .block')];
  const blockIndex = blocks.indexOf(block);
  const card = target.closest('.exercise');
  const stationIndex = card && block ? [...block.querySelectorAll('.exercise')].indexOf(card) : 0;
  return { blockIndex, stationIndex };
}

function exerciseBlock(exercise) {
  return { type: 'exercise', exercise };
}

function blankCircuit() {
  return {
    type: 'circuit',
    id: newId(),
    rounds: 3,
    restBetweenRoundsSeconds: 60,
    exercises: [blankStation()],
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

function blankStation() {
  return {
    id: newId(),
    name: '',
    type: 'sets',
    sets: 1,
    reps: 10,
    restSeconds: 15,
    workSeconds: 40,
  };
}

function numberIn(node, selector) {
  return Number(node.querySelector(selector).value);
}
