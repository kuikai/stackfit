import { workoutBlocks } from './snapshot.js';

let audio;

export function renderRun(run) {
  const exercise = run.workout.exercises?.[run.exerciseIndex];
  const panel = document.querySelector('#workout-run');
  panel.hidden = false;
  panel.className = `panel tabata-run ${run.phase}`;
  document.querySelector('#run-progress').textContent = progressLabel(run);
  document.querySelector('#run-name').textContent = exercise?.name || run.workout.name;
  document.querySelector('#run-phase').textContent = phaseLabel(run.phase);
  document.querySelector('#run-detail').textContent = detailLabel(run, exercise);
  const clockNode = document.querySelector('#run-clock');
  const showSet = run.phase === 'set';
  clockNode.textContent = showSet ? setLabel(run, exercise) : formatClock(run.remaining);
  clockNode.className = showSet ? 'tabata-clock set-prompt' : 'tabata-clock';
  renderControls(run);
  if (run.phase === 'work' || run.phase === 'rest') {
    document.title = `${formatClock(run.remaining)} ${phaseLabel(run.phase)}`;
  }
}

export function showRunPanel() {
  document.querySelector('#library').hidden = true;
  document.querySelector('#receive').hidden = true;
  document.querySelector('#share-link-box').hidden = true;
  document.querySelector('#progress-picker').hidden = true;
  document.querySelector('#editor').hidden = true;
  document.querySelector('#session-editor').hidden = true;
  document.querySelector('#workout-run').hidden = false;
}

export function prepareSound() {
  const Context = window.AudioContext || window.webkitAudioContext;
  if (!Context || audio) {
    return;
  }
  audio = new Context();
}

export function playTone(frequency) {
  if (!audio) {
    return;
  }
  const tone = audio.createOscillator();
  const gain = audio.createGain();
  tone.frequency.value = frequency;
  gain.gain.value = 0.04;
  tone.connect(gain);
  gain.connect(audio.destination);
  tone.start();
  tone.stop(audio.currentTime + 0.12);
}

function renderControls(run) {
  const primary = document.querySelector('#run-primary');
  const pause = document.querySelector('#run-pause');
  primary.hidden = run.phase === 'work';
  primary.textContent = run.phase === 'rest' ? 'Skip rest' : 'Done';
  pause.hidden = run.phase === 'set';
  pause.textContent = run.paused ? 'Resume' : 'Pause';
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

function phaseLabel(phase) {
  if (phase === 'rest') {
    return 'Rest';
  }
  if (phase === 'set') {
    return 'Set';
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
    return `Set ${state.setIndex + 1} of ${total}`;
  }
  return '';
}

function setLabel(state, exercise) {
  const total = exercise?.sets ?? 1;
  return `Set ${state.setIndex + 1} of ${total}`;
}

function formatClock(totalSeconds) {
  const safe = Math.max(0, totalSeconds);
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  return `${minutes}:${String(seconds).padStart(2, '0')}`;
}
