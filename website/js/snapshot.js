const months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

export function emptySnapshot() {
  return {
    workouts: [],
    deletedWorkouts: [],
    sessions: [],
    themeMode: 'system',
    skin: 'classic',
    appearanceUpdatedAt: '1970-01-01T00:00:00.000Z',
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
    themeMode: snapshot.themeMode || 'system',
    skin: snapshot.skin || 'classic',
    appearanceUpdatedAt:
      snapshot.appearanceUpdatedAt || '1970-01-01T00:00:00.000Z',
  };
}

/// Same rules as lib/services/account/snapshot_merge.dart.
export function mergeSnapshots(local, remote) {
  const workouts = mergeWorkouts(local, remote);
  const appearance = newerAppearance(local, remote);
  return {
    workouts: workouts.workouts,
    deletedWorkouts: workouts.deletions,
    sessions: mergeSessions(local.sessions, remote.sessions),
    themeMode: appearance.themeMode,
    skin: appearance.skin,
    appearanceUpdatedAt: appearance.appearanceUpdatedAt,
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

export function dateTimeLocalValue(date) {
  const pad = (value) => String(value).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
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
  keptWorkouts.sort((a, b) => a.name.localeCompare(b.name));
  return { workouts: keptWorkouts, deletions: keptDeletions };
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

function mergeSessions(local, remote) {
  const byId = new Map();
  for (const session of [...(local || []), ...(remote || [])]) {
    if (!byId.has(session.id)) {
      byId.set(session.id, session);
    }
  }
  return [...byId.values()].sort(
    (a, b) => Date.parse(b.completedAt) - Date.parse(a.completedAt),
  );
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
