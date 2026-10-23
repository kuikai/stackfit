import { newId } from './snapshot.js';
import {
  bindBlockEditor,
  blocksProblem,
  readBlocks,
  renderBlocks,
  stationsFromBlocks,
} from './editor_blocks.js';

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
  renderBlocks(blocksForEditor(workout));
  editor.hidden = false;
}

export function closeWorkoutEditor() {
  document.querySelector('#editor').hidden = true;
}

export function readWorkoutDraft() {
  const blocks = readBlocks();
  const workout = {
    id: draftId,
    name: document.querySelector('#workout-name').value.trim(),
    blocks,
    exercises: stationsFromBlocks(blocks),
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
  const problem = blocksProblem(workout.blocks || []);
  return problem || null;
}

export function bindExerciseActions() {
  bindBlockEditor();
}

function blocksForEditor(workout) {
  if (Array.isArray(workout?.blocks) && workout.blocks.length > 0) {
    return workout.blocks;
  }
  const exercises = workout?.exercises?.length ? workout.exercises : [blankExercise()];
  return exercises.map((exercise) => ({ type: 'exercise', exercise }));
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
