import { blockNode, stepNumber } from './editor_cards.js';
import { blockStations, newId } from './snapshot.js';

export function bindBlockEditor() {
  document.querySelector('#add-exercise').addEventListener('click', () => {
    renderBlocks([...readBlocks(), exerciseBlock(blankExercise())]);
    focusLastName();
  });
  document.querySelector('#add-circuit').addEventListener('click', () => {
    renderBlocks([...readBlocks(), blankCircuit()]);
    focusLastName();
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

function focusLastName() {
  const names = document.querySelectorAll('#exercise-list .exercise-name');
  names[names.length - 1]?.focus();
}

function onListClick(event) {
  const step = event.target.closest('[data-step]');
  if (step) {
    stepNumber(step);
    return;
  }
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
    const box = document.querySelectorAll('#exercise-list > .block')[place.blockIndex];
    const names = box.querySelectorAll('.exercise-name');
    names[names.length - 1]?.focus();
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
