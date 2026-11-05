import { workoutBlocks } from './snapshot.js';
import { formatClock, setPhaseBar, setTimerOpen } from './timer_screen.js';

let phaseKey = '';
let phaseTotal = 0;

export function renderRun(run) {
  const exercise = exerciseAt(run, run.blockIndex, run.exerciseIndex);
  const panel = document.querySelector('#workout-run');
  panel.hidden = false;
  panel.className = `timer-screen ${run.phase}${run.paused ? ' paused' : ''}`;
  document.querySelector('#run-progress').textContent = progressLabel(run);
  document.querySelector('#run-name').textContent = exercise?.name || run.workout.name;
  document.querySelector('#run-phase').textContent = phaseLabel(run);
  document.querySelector('#run-detail').textContent = detailLabel(run, exercise);
  document.querySelector('#run-next').textContent = nextLabel(run);
  const clockNode = document.querySelector('#run-clock');
  const showSet = run.phase === 'set';
  clockNode.textContent = showSet ? setLabel(run, exercise) : formatClock(run.remaining);
  clockNode.className = showSet ? 'tabata-clock set-prompt' : 'tabata-clock';
  renderBar(run);
  renderControls(run);
  if (run.phase === 'work' || run.phase === 'rest') {
    document.title = `${formatClock(run.remaining)} ${phaseLabel(run)}`;
  }
}

export function showRunPanel() {
  for (const id of ['library', 'receive', 'share-link-box', 'progress-picker', 'editor']) {
    document.querySelector(`#${id}`).hidden = true;
  }
  document.querySelector('#workout-run').hidden = false;
  phaseKey = '';
  setTimerOpen(true);
}

function renderBar(run) {
  const bar = document.querySelector('#run-bar');
  const timed = run.phase === 'work' || run.phase === 'rest';
  bar.parentElement.hidden = !timed;
  if (!timed) {
    return;
  }
  const key = [run.blockIndex, run.roundIndex, run.exerciseIndex, run.setIndex, run.phase].join('-');
  if (key !== phaseKey) {
    phaseKey = key;
    phaseTotal = run.remaining;
  }
  setPhaseBar(bar, run.remaining, phaseTotal);
}

function renderControls(run) {
  const primary = document.querySelector('#run-primary');
  const pause = document.querySelector('#run-pause');
  primary.hidden = run.phase === 'work';
  primary.textContent = run.phase === 'rest' ? 'Skip rest' : 'Done';
  document.querySelector('#run-skip').hidden = run.phase === 'rest';
  pause.hidden = run.phase === 'set';
  pause.textContent = run.paused ? 'Resume' : 'Pause';
}

function exerciseAt(run, blockIndex, exerciseIndex) {
  const block = workoutBlocks(run.workout)[blockIndex];
  if (!block) {
    return undefined;
  }
  if (block.type === 'circuit') {
    return block.exercises?.[exerciseIndex];
  }
  return block.exercise;
}

function progressLabel(state) {
  const blocks = workoutBlocks(state.workout);
  const block = blocks[state.blockIndex];
  if (block?.type === 'circuit') {
    const stations = block.exercises?.length ?? 0;
    const round = (state.roundIndex ?? 0) + 1;
    const rounds = block.rounds || 1;
    const station = Math.min((state.exerciseIndex ?? 0) + 1, stations);
    return `Round ${round} of ${rounds} · Station ${station} of ${stations}`;
  }
  const total = blocks.length;
  const number = Math.min((state.blockIndex ?? 0) + 1, total);
  return `Exercise ${number} of ${total}`;
}

function phaseLabel(run) {
  if (run.paused) {
    return 'Paused';
  }
  if (run.phase === 'rest') {
    return 'Rest';
  }
  if (run.phase === 'set') {
    return 'Your set';
  }
  return 'Work';
}

function detailLabel(state, exercise) {
  if (!exercise) {
    return '';
  }
  if (state.phase === 'set') {
    return exercise.reps ? `${exercise.reps} reps` : '';
  }
  const total = exercise.sets ?? 1;
  if (total > 1) {
    const unit = exercise.type === 'timer' ? 'Round' : 'Set';
    return `${unit} ${state.setIndex + 1} of ${total}`;
  }
  return '';
}

/// What starts when this rest ends, so the next move is never a surprise.
function nextLabel(run) {
  if (run.phase !== 'rest') {
    return '';
  }
  const after = run.afterRest || 'block';
  if (after === 'set' || after === 'timerRound') {
    const exercise = exerciseAt(run, run.blockIndex, run.exerciseIndex);
    const unit = after === 'set' ? 'set' : 'round';
    return `Next: ${exercise?.name || 'next'} · ${unit} ${run.setIndex + 2}`;
  }
  if (after === 'station') {
    return nextNameLabel(exerciseAt(run, run.blockIndex, run.exerciseIndex + 1));
  }
  if (after === 'round') {
    return nextNameLabel(exerciseAt(run, run.blockIndex, 0));
  }
  return nextNameLabel(firstExerciseFrom(run, run.blockIndex + 1));
}

function firstExerciseFrom(run, blockIndex) {
  const blocks = workoutBlocks(run.workout);
  for (let index = blockIndex; index < blocks.length; index += 1) {
    const exercise = exerciseAt(run, index, 0);
    if (exercise) {
      return exercise;
    }
  }
  return undefined;
}

function nextNameLabel(exercise) {
  return exercise ? `Next: ${exercise.name}` : 'Next: finish';
}

function setLabel(state, exercise) {
  const total = exercise?.sets ?? 1;
  return `Set ${state.setIndex + 1} of ${total}`;
}
