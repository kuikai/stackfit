import { blockStations } from './snapshot.js';

export function stationsFromBlocks(blocks) {
  return blocks.flatMap((block) => blockStations(block));
}

/// The first thing wrong with the draft, in plain words, or '' when it can be saved.
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
