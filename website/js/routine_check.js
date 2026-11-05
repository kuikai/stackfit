import { workoutBlocks, workoutStations } from './snapshot.js';

export function parseRoutineText(raw) {
  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return { error: 'That file is not a StackFit routine.' };
  }
  const error = routineError(parsed);
  if (error) {
    return { error };
  }
  const workout = {
    name: String(parsed.name).trim(),
    exercises: parsed.exercises,
  };
  if (Array.isArray(parsed.blocks) && parsed.blocks.length > 0) {
    workout.blocks = parsed.blocks;
  }
  return { workout };
}

export function routineError(workout) {
  if (!workout || typeof workout.name !== 'string' || !workout.name.trim()) {
    return 'A routine needs a name.';
  }
  const blocks = workoutBlocks(workout);
  if (workoutStations(workout).length === 0) {
    return 'A routine needs at least one exercise.';
  }
  for (const block of blocks) {
    if (block.type === 'circuit') {
      const rounds = block.rounds;
      const rest = block.restBetweenRoundsSeconds ?? 0;
      if (!Number.isInteger(rounds) || rounds < 1) {
        return 'Circuit rounds must be at least 1.';
      }
      if (!Number.isInteger(rest) || rest < 0) {
        return 'Enter a valid rest between rounds.';
      }
      if (!Array.isArray(block.exercises) || block.exercises.length === 0) {
        return 'A circuit needs at least one exercise.';
      }
    }
    for (const exercise of block.type === 'circuit' ? block.exercises : [block.exercise]) {
      const error = exerciseError(exercise);
      if (error) {
        return error;
      }
    }
  }
  return '';
}

function exerciseError(exercise) {
  if (!exercise || typeof exercise.name !== 'string' || !exercise.name.trim()) {
    return 'Each exercise needs a name.';
  }
  if (exercise.type === 'timer') {
    return numberError(exercise.workSeconds, 1, 'Work time must be at least 1 second.')
      || numberError(exercise.restSeconds, 0, 'Enter a valid rest time.')
      || numberError(exercise.sets, 1, 'Sets must be at least 1.');
  }
  if (exercise.type !== 'sets') {
    return 'Each exercise must be timer or sets.';
  }
  const reps = exercise.reps;
  if (reps != null && (!Number.isInteger(reps) || reps < 1)) {
    return 'Reps must be a positive number.';
  }
  return numberError(exercise.sets, 1, 'Sets must be at least 1.')
    || numberError(exercise.restSeconds, 0, 'Enter a valid rest time.');
}

function numberError(value, minimum, message) {
  if (!Number.isInteger(value) || value < minimum) {
    return message;
  }
  return '';
}
