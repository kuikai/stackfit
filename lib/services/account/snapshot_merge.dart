import '../../models/account_snapshot.dart';
import '../../models/completed_session.dart';
import '../../models/workout.dart';

/// Combines two devices without losing the newer edit.
///
/// Workouts: newer [Workout.updatedAt] wins. A deletion wins when its
/// timestamp is the same or newer than the workout.
/// History: sessions are unioned by id, so the same session is stored once.
/// Appearance: the newer [AccountSnapshot.appearanceUpdatedAt] wins.
AccountSnapshot mergeSnapshots(AccountSnapshot local, AccountSnapshot remote) {
  final workouts = _mergeWorkouts(local, remote);
  final appearance = _newerAppearance(local, remote);
  return AccountSnapshot(
    workouts: workouts.workouts,
    deletedWorkouts: workouts.deletions,
    sessions: _mergeSessions(local.sessions, remote.sessions),
    themeMode: appearance.themeMode,
    skin: appearance.skin,
    appearanceUpdatedAt: appearance.appearanceUpdatedAt,
  );
}

class _WorkoutMerge {
  const _WorkoutMerge({
    required this.workouts,
    required this.deletions,
  });

  final List<Workout> workouts;
  final List<WorkoutDeletion> deletions;
}

_WorkoutMerge _mergeWorkouts(AccountSnapshot local, AccountSnapshot remote) {
  final workouts = <String, Workout>{};
  final deletions = <String, DateTime>{};

  _keepWorkouts(workouts, local.workouts);
  _keepWorkouts(workouts, remote.workouts);
  _keepDeletions(deletions, local.deletedWorkouts);
  _keepDeletions(deletions, remote.deletedWorkouts);

  final keptWorkouts = <Workout>[];
  final keptDeletions = <WorkoutDeletion>[];
  final ids = {...workouts.keys, ...deletions.keys};

  for (final id in ids) {
    final workout = workouts[id];
    final deletedAt = deletions[id];
    if (_deletionWins(deletedAt, workout)) {
      keptDeletions.add(WorkoutDeletion(id: id, deletedAt: deletedAt!));
      continue;
    }
    if (workout != null) {
      keptWorkouts.add(workout);
    }
  }

  keptWorkouts.sort((a, b) => a.name.compareTo(b.name));
  return _WorkoutMerge(workouts: keptWorkouts, deletions: keptDeletions);
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
  List<WorkoutDeletion> incoming,
) {
  for (final deletion in incoming) {
    final existing = deletions[deletion.id];
    if (existing == null || !deletion.deletedAt.isBefore(existing)) {
      deletions[deletion.id] = deletion.deletedAt;
    }
  }
}

bool _deletionWins(DateTime? deletedAt, Workout? workout) {
  if (deletedAt == null) {
    return false;
  }
  if (workout == null) {
    return true;
  }
  return !deletedAt.isBefore(workout.updatedAt);
}

List<CompletedSession> _mergeSessions(
  List<CompletedSession> local,
  List<CompletedSession> remote,
) {
  final byId = <String, CompletedSession>{};
  for (final session in [...local, ...remote]) {
    byId.putIfAbsent(session.id, () => session);
  }
  final sessions = byId.values.toList();
  sessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return sessions;
}

AccountSnapshot _newerAppearance(AccountSnapshot local, AccountSnapshot remote) {
  if (remote.appearanceUpdatedAt.isBefore(local.appearanceUpdatedAt)) {
    return local;
  }
  return remote;
}
