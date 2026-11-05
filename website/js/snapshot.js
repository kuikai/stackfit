const months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

export function emptySnapshot() {
  return {
    workouts: [],
    deletedWorkouts: [],
    sessions: [],
    deletedSessions: [],
    customExercises: [],
    themeMode: 'system',
    skin: 'classic',
    appearanceUpdatedAt: '1970-01-01T00:00:00.000Z',
    homeOrderUpdatedAt: '1970-01-01T00:00:00.000Z',
  };
}

export function cloneSnapshot(snapshot) {
  return ensureSnapshot(JSON.parse(JSON.stringify(snapshot)));
}

export function ensureSnapshot(raw) {
  const snapshot = raw && typeof raw === 'object' ? raw : {};
  return {
    workouts: Array.isArray(snapshot.workouts) ? snapshot.workouts : [],
    deletedWorkouts: Array.isArray(snapshot.deletedWorkouts)
      ? snapshot.deletedWorkouts
      : [],
    sessions: Array.isArray(snapshot.sessions) ? snapshot.sessions : [],
    deletedSessions: Array.isArray(snapshot.deletedSessions)
      ? snapshot.deletedSessions
      : [],
    customExercises: Array.isArray(snapshot.customExercises)
      ? snapshot.customExercises
      : [],
    themeMode: snapshot.themeMode || 'system',
    skin: snapshot.skin || 'classic',
    appearanceUpdatedAt:
      snapshot.appearanceUpdatedAt || '1970-01-01T00:00:00.000Z',
    homeOrderUpdatedAt:
      snapshot.homeOrderUpdatedAt || '1970-01-01T00:00:00.000Z',
  };
}

/// Same rules as lib/services/account/snapshot_merge.dart.
export function mergeSnapshots(local, remote) {
  const workouts = mergeWorkouts(local, remote);
  const history = mergeSessions(local, remote);
  const appearance = newerAppearance(local, remote);
  return {
    workouts: workouts.workouts,
    deletedWorkouts: workouts.deletions,
    sessions: history.sessions,
    deletedSessions: history.deletions,
    customExercises: mergeCustomExercises(
      local.customExercises,
      remote.customExercises,
    ),
    themeMode: appearance.themeMode,
    skin: appearance.skin,
    appearanceUpdatedAt: appearance.appearanceUpdatedAt,
    homeOrderUpdatedAt: workouts.homeOrderUpdatedAt,
  };
}

export function newId() {
  if (globalThis.crypto?.randomUUID) {
    return globalThis.crypto.randomUUID();
  }
  return `id-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function formatDuration(totalSeconds) {
  const safe = totalSeconds < 0 ? 0 : totalSeconds;
  const minutes = Math.floor(safe / 60);
  const seconds = safe % 60;
  if (minutes > 0) {
    return `${minutes}m ${seconds}s`;
  }
  return `${seconds}s`;
}

export function formatSessionDate(iso) {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) {
    return iso;
  }
  const day = String(date.getDate()).padStart(2, '0');
  const month = months[date.getMonth()];
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');
  return `${day} ${month} ${date.getFullYear()} · ${hour}:${minute}`;
}

export function estimatedDurationSeconds(exercises) {
  let total = 0;
  for (const exercise of exercises) {
    if (exercise.type === 'timer') {
      const rounds = exercise.sets ?? 1;
      total += ((exercise.workSeconds ?? 0) + (exercise.restSeconds ?? 0)) * rounds;
    } else {
      const sets = exercise.sets ?? 1;
      const rest = Math.max(sets - 1, 0) * (exercise.restSeconds ?? 0);
      total += sets * 45 + rest;
    }
  }
  return total;
}

export function exerciseLine(exercise) {
  if (exercise.type === 'timer') {
    const rounds = exercise.sets ?? 1;
    const roundsText = rounds > 1 ? ` · ${rounds} rounds` : '';
    return `${exercise.name} (${exercise.workSeconds}s work / ${exercise.restSeconds}s rest${roundsText})`;
  }
  const repsText = exercise.reps != null ? ` × ${exercise.reps} reps` : '';
  return `${exercise.name} (${exercise.sets} sets${repsText} / ${exercise.restSeconds}s rest)`;
}

/// Saved blocks, or one block per exercise when the workout is from before circuits.
export function workoutBlocks(workout) {
  if (Array.isArray(workout?.blocks) && workout.blocks.length > 0) {
    return workout.blocks;
  }
  return (workout?.exercises || []).map((exercise) => ({ type: 'exercise', exercise }));
}

export function blockStations(block) {
  if (block?.type === 'circuit') {
    return block.exercises || [];
  }
  return block?.exercise ? [block.exercise] : [];
}

export function workoutStations(workout) {
  return workoutBlocks(workout).flatMap(blockStations);
}

export function estimatedWorkoutSeconds(workout) {
  let total = 0;
  for (const block of workoutBlocks(workout)) {
    if (block.type !== 'circuit') {
      total += estimatedDurationSeconds(blockStations(block));
      continue;
    }
    const rounds = Math.max(1, block.rounds || 1);
    const between = Math.max(0, block.restBetweenRoundsSeconds || 0);
    total += estimatedDurationSeconds(block.exercises || []) * rounds;
    total += between * Math.max(rounds - 1, 0);
  }
  return total;
}

export function workoutLines(workout) {
  const lines = [];
  for (const block of workoutBlocks(workout)) {
    if (block.type === 'circuit') {
      const rounds = block.rounds || 1;
      const rest = block.restBetweenRoundsSeconds || 0;
      const restText = rest > 0 ? ` · ${rest}s between rounds` : '';
      lines.push(`Circuit · ${rounds} rounds${restText}`);
      for (const exercise of block.exercises || []) {
        lines.push(`  ${exerciseLine(exercise)}`);
      }
      continue;
    }
    if (block.exercise) {
      lines.push(exerciseLine(block.exercise));
    }
  }
  return lines;
}

function mergeWorkouts(local, remote) {
  const workouts = new Map();
  const deletions = new Map();
  keepWorkouts(workouts, local.workouts);
  keepWorkouts(workouts, remote.workouts);
  keepDeletions(deletions, local.deletedWorkouts);
  keepDeletions(deletions, remote.deletedWorkouts);

  const keptWorkouts = [];
  const keptDeletions = [];
  const ids = new Set([...workouts.keys(), ...deletions.keys()]);
  for (const id of ids) {
    const workout = workouts.get(id);
    const deletedAt = deletions.get(id);
    if (deletionWins(deletedAt, workout)) {
      keptDeletions.push({ id, deletedAt });
      continue;
    }
    if (workout) {
      keptWorkouts.push(workout);
    }
  }
  const order = newerHomeOrder(local, remote);
  return {
    workouts: arrangeWorkouts(keptWorkouts, order),
    deletions: keptDeletions,
    homeOrderUpdatedAt: order.updatedAt,
  };
}

const homeOrderEpoch = '1970-01-01T00:00:00.000Z';

function newerHomeOrder(local, remote) {
  const localAt = local?.homeOrderUpdatedAt || homeOrderEpoch;
  const remoteAt = remote?.homeOrderUpdatedAt || homeOrderEpoch;
  if (isBefore(remoteAt, localAt)) {
    return {
      updatedAt: localAt,
      primary: local?.workouts || [],
      secondary: remote?.workouts || [],
    };
  }
  return {
    updatedAt: remoteAt,
    primary: remote?.workouts || [],
    secondary: local?.workouts || [],
  };
}

function arrangeWorkouts(kept, order) {
  if (!(Date.parse(order.updatedAt) > Date.parse(homeOrderEpoch))) {
    return [...kept].sort((left, right) => left.name.localeCompare(right.name));
  }
  const byId = new Map(kept.map((workout) => [workout.id, workout]));
  const ordered = [];
  const seen = new Set();
  for (const source of [order.primary, order.secondary]) {
    for (const workout of source) {
      const match = byId.get(workout.id);
      if (match && !seen.has(match.id)) {
        seen.add(match.id);
        ordered.push(match);
      }
    }
  }
  for (const workout of kept) {
    if (!seen.has(workout.id)) {
      seen.add(workout.id);
      ordered.push(workout);
    }
  }
  return ordered;
}

function keepWorkouts(workouts, incoming) {
  for (const workout of incoming || []) {
    const existing = workouts.get(workout.id);
    if (!existing || !isBefore(workout.updatedAt, existing.updatedAt)) {
      workouts.set(workout.id, workout);
    }
  }
}

function keepDeletions(deletions, incoming) {
  for (const deletion of incoming || []) {
    const existing = deletions.get(deletion.id);
    if (!existing || !isBefore(deletion.deletedAt, existing)) {
      deletions.set(deletion.id, deletion.deletedAt);
    }
  }
}

function deletionWins(deletedAt, workout) {
  if (!deletedAt) {
    return false;
  }
  if (!workout) {
    return true;
  }
  return !isBefore(deletedAt, workout.updatedAt);
}

function mergeCustomExercises(local, remote) {
  const byName = new Map();
  for (const item of [...(local || []), ...(remote || [])]) {
    const name = typeof item?.name === 'string' ? item.name.trim() : '';
    const key = name.toLowerCase();
    if (!key || byName.has(key)) {
      continue;
    }
    byName.set(key, item);
  }
  return [...byName.values()].sort((left, right) =>
    left.name.toLowerCase().localeCompare(right.name.toLowerCase()),
  );
}

function mergeSessions(local, remote) {
  const deletions = new Map();
  keepDeletions(deletions, local.deletedSessions);
  keepDeletions(deletions, remote.deletedSessions);
  const byId = new Map();
  for (const session of [...(local.sessions || []), ...(remote.sessions || [])]) {
    const existing = byId.get(session.id);
    byId.set(session.id, existing ? sharedSetLogs(existing, session) : session);
  }
  const keptDeletions = [];
  for (const [id, deletedAt] of deletions) {
    byId.delete(id);
    keptDeletions.push({ id, deletedAt });
  }
  const sessions = [...byId.values()].sort(
    (a, b) => Date.parse(b.completedAt) - Date.parse(a.completedAt),
  );
  return { sessions, deletions: keptDeletions };
}

function sharedSetLogs(first, second) {
  const keys = new Set((second.setLogs || []).map(setLogKey));
  const logs = first.setLogs || [];
  const shared = logs.filter((log) => keys.has(setLogKey(log)));
  if (shared.length === logs.length) {
    return first;
  }
  return { ...first, setLogs: shared };
}

function setLogKey(log) {
  const round = log.round == null ? 1 : log.round;
  return `${log.exerciseId}|${round}|${log.setNumber}`;
}

function newerAppearance(local, remote) {
  if (isBefore(remote.appearanceUpdatedAt, local.appearanceUpdatedAt)) {
    return local;
  }
  return remote;
}

function isBefore(left, right) {
  return Date.parse(left) < Date.parse(right);
}
