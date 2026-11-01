import '../../models/account_snapshot.dart';
import '../../models/catalog_exercise.dart';
import '../../models/completed_session.dart';
import '../../models/workout.dart';

/// Combines two devices without losing the newer edit.
///
/// Workouts: newer [Workout.updatedAt] wins. A deletion wins when its
/// timestamp is the same or newer than the workout.
/// History: sessions are unioned by id, then any id in [AccountSnapshot.deletedSessions]
/// is dropped. A session deletion always wins; sessions have no updatedAt.
/// Custom exercises: union by name, ignoring case. The local copy is kept
/// when both devices have that name.
/// Appearance: the newer [AccountSnapshot.appearanceUpdatedAt] wins.
AccountSnapshot mergeSnapshots(AccountSnapshot local, AccountSnapshot remote) {
  final workouts = _mergeWorkouts(local, remote);
  final sessions = _mergeSessions(local, remote);
  final appearance = _newerAppearance(local, remote);
  return AccountSnapshot(
    workouts: workouts.workouts,
    deletedWorkouts: workouts.deletions,
    sessions: sessions.sessions,
    deletedSessions: sessions.deletions,
    customExercises: _mergeCustomExercises(
      local.customExercises,
      remote.customExercises,
    ),
    themeMode: appearance.themeMode,
    skin: appearance.skin,
    appearanceUpdatedAt: appearance.appearanceUpdatedAt,
  );
}

class _WorkoutMerge {
  const _WorkoutMerge({required this.workouts, required this.deletions});

  final List<Workout> workouts;
  final List<SnapshotDeletion> deletions;
}

class _SessionMerge {
  const _SessionMerge({required this.sessions, required this.deletions});

  final List<CompletedSession> sessions;
  final List<SnapshotDeletion> deletions;
}

_WorkoutMerge _mergeWorkouts(AccountSnapshot local, AccountSnapshot remote) {
  final workouts = <String, Workout>{};
  final deletions = <String, DateTime>{};

  _keepWorkouts(workouts, local.workouts);
  _keepWorkouts(workouts, remote.workouts);
  _keepDeletions(deletions, local.deletedWorkouts);
  _keepDeletions(deletions, remote.deletedWorkouts);

  final keptWorkouts = <Workout>[];
  final keptDeletions = <SnapshotDeletion>[];
  final ids = {...workouts.keys, ...deletions.keys};

  for (final id in ids) {
    final workout = workouts[id];
    final deletedAt = deletions[id];
    if (_workoutDeletionWins(deletedAt, workout)) {
      keptDeletions.add(SnapshotDeletion(id: id, deletedAt: deletedAt!));
      continue;
    }
    if (workout != null) {
      keptWorkouts.add(workout);
    }
  }

  keptWorkouts.sort((a, b) => a.name.compareTo(b.name));
  return _WorkoutMerge(workouts: keptWorkouts, deletions: keptDeletions);
}

_SessionMerge _mergeSessions(AccountSnapshot local, AccountSnapshot remote) {
  final sessions = <String, CompletedSession>{};
  for (final session in [...local.sessions, ...remote.sessions]) {
    sessions.putIfAbsent(session.id, () => session);
  }

  final deletions = <String, DateTime>{};
  _keepDeletions(deletions, local.deletedSessions);
  _keepDeletions(deletions, remote.deletedSessions);

  final keptSessions = <CompletedSession>[];
  final keptDeletions = <SnapshotDeletion>[];
  final ids = {...sessions.keys, ...deletions.keys};

  for (final id in ids) {
    final deletedAt = deletions[id];
    if (deletedAt != null) {
      keptDeletions.add(SnapshotDeletion(id: id, deletedAt: deletedAt));
      continue;
    }
    final session = sessions[id];
    if (session != null) {
      keptSessions.add(session);
    }
  }

  keptSessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return _SessionMerge(sessions: keptSessions, deletions: keptDeletions);
}

void _keepWorkouts(Map<String, Workout> workouts, List<Workout> incoming) {
  for (final workout in incoming) {
    final existing = workouts[workout.id];
    // Remote is applied second, so an equal timestamp keeps the remote copy.
    if (existing == null || !workout.updatedAt.isBefore(existing.updatedAt)) {
      workouts[workout.id] = workout;
    }
  }
}

void _keepDeletions(
  Map<String, DateTime> deletions,
  List<SnapshotDeletion> incoming,
) {
  for (final deletion in incoming) {
    final existing = deletions[deletion.id];
    if (existing == null || !deletion.deletedAt.isBefore(existing)) {
      deletions[deletion.id] = deletion.deletedAt;
    }
  }
}

bool _workoutDeletionWins(DateTime? deletedAt, Workout? workout) {
  if (deletedAt == null) {
    return false;
  }
  if (workout == null) {
    return true;
  }
  return !deletedAt.isBefore(workout.updatedAt);
}

List<CatalogExercise> _mergeCustomExercises(
  List<CatalogExercise> local,
  List<CatalogExercise> remote,
) {
  final byName = <String, CatalogExercise>{};
  for (final item in [...local, ...remote]) {
    final key = item.name.trim().toLowerCase();
    if (key.isEmpty) {
      continue;
    }
    byName.putIfAbsent(key, () => item);
  }
  final merged = byName.values.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return merged;
}

AccountSnapshot _newerAppearance(
  AccountSnapshot local,
  AccountSnapshot remote,
) {
  if (remote.appearanceUpdatedAt.isBefore(local.appearanceUpdatedAt)) {
    return local;
  }
  return remote;
}
