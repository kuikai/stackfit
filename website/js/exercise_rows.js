import { shortMinutes } from './history.js';
import { estimatedWorkoutSeconds, workoutBlocks, workoutStations } from './snapshot.js';

export function workoutSummary(workout) {
  const count = workoutStations(workout).length;
  const circuits = workoutBlocks(workout).filter((block) => block.type === 'circuit').length;
  const circuitText = circuits > 0 ? ` · ${circuits === 1 ? '1 circuit' : `${circuits} circuits`}` : '';
  return `${count === 1 ? '1 exercise' : `${count} exercises`}${circuitText} · ≈ ${shortMinutes(estimatedWorkoutSeconds(workout))}`;
}

export function exerciseList(workout) {
  const list = document.createElement('ul');
  list.className = 'exercise-rows';
  for (const block of workoutBlocks(workout)) {
    if (block.type !== 'circuit') {
      if (block.exercise) {
        list.append(exerciseRow(block.exercise));
      }
      continue;
    }
    const head = document.createElement('li');
    head.className = 'circuit-label';
    const rest = block.restBetweenRoundsSeconds || 0;
    head.textContent = `Circuit × ${block.rounds || 1}${rest > 0 ? ` · ${rest}s between rounds` : ''}`;
    list.append(head);
    for (const exercise of block.exercises || []) {
      const row = exerciseRow(exercise);
      row.classList.add('in-circuit');
      list.append(row);
    }
  }
  return list;
}

function exerciseRow(exercise) {
  const row = document.createElement('li');
  const name = document.createElement('span');
  name.textContent = exercise.name;
  const spec = document.createElement('span');
  spec.className = 'spec';
  spec.textContent = exerciseSpec(exercise);
  row.append(name, spec);
  return row;
}

function exerciseSpec(exercise) {
  const rest = exercise.restSeconds ?? 0;
  const restText = rest > 0 ? ` · ${rest}s rest` : '';
  if (exercise.type === 'timer') {
    const rounds = exercise.sets ?? 1;
    return `${exercise.workSeconds}s${rounds > 1 ? ` × ${rounds}` : ''}${restText}`;
  }
  const reps = exercise.reps != null ? ` × ${exercise.reps}` : ' sets';
  return `${exercise.sets}${reps}${restText}`;
}
