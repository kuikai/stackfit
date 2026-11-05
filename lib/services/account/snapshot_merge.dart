import '../../models/account_snapshot.dart';
import '../../models/catalog_exercise.dart';
import '../../models/completed_session.dart';
import '../../models/set_log.dart';
import '../../models/workout.dart';

/// Combines two devices without losing the newer edit.
///
/// Workouts: newer [Workout.updatedAt] wins. A deletion wins when its
/// timestamp is the same or newer than the workout.
/// History: one row per session id. A deleted session stays deleted. When both
/// sides still have that session, a set log stays only if both still have it.
/// A session only one side has is kept.
/// Custom exercises: union by name, ignoring case. The local copy is kept
/// when both devices have that name.
/// Appearance: the newer [AccountSnapshot.appearanceUpdatedAt] wins.
/// Home order: the newer [AccountSnapshot.homeOrderUpdatedAt] wins. Until
/// someone rearranges Home, workouts stay alphabetical.
AccountSnapshot mergeSnapshots(AccountSnapshot local, AccountSnapshot remote) {
  final workouts = _mergeWorkouts(local, remote);
  final history = _mergeSessions(local, remote);
  final appearance = _newerAppearance(local, remote);
  final homeOrder = _newerHomeOrder(local, remote);
  return AccountSnapshot(
    workouts: _arrangeHomeOrder(workouts.workouts, homeOrder),
    deletedWorkouts: workouts.deletions,
    sessions: history.sessions,
    deletedSessions: history.deletions,
    customExercises: _mergeCustomExercises(
      local.customExercises,
      remote.customExercises,
    ),
    themeMode: appearance.themeMode,
    skin: appearance.skin,
    appearanceUpdatedAt: appearance.appearanceUpdatedAt,
    homeOrderUpdatedAt: homeOrder.updatedAt,
  );
}

class _WorkoutMerge {
  const _WorkoutMerge({required this.workouts, required this.deletions});

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

  return _WorkoutMerge(workouts: keptWorkouts, deletions: keptDeletions);
}

class _HomeOrder {
  const _HomeOrder({
    required this.updatedAt,
    required this.primary,
    required this.secondary,
  });

  final DateTime updatedAt;
  final List<Workout> primary;
  final List<Workout> secondary;

  bool get isCustom => updatedAt.isAfter(DateTime.utc(1970));
}

/// Equal timestamps keep the remote arrangement, same as workout edits.
_HomeOrder _newerHomeOrder(AccountSnapshot local, AccountSnapshot remote) {
  if (remote.homeOrderUpdatedAt.isBefore(local.homeOrderUpdatedAt)) {
    return _HomeOrder(
      updatedAt: local.homeOrderUpdatedAt,
      primary: local.workouts,
      secondary: remote.workouts,
    );
  }
  return _HomeOrder(
    updatedAt: remote.homeOrderUpdatedAt,
    primary: remote.workouts,
    secondary: local.workouts,
  );
}

List<Workout> _arrangeHomeOrder(List<Workout> kept, _HomeOrder order) {
  if (!order.isCustom) {
    final sorted = [...kept]..sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }
  final byId = {for (final workout in kept) workout.id: workout};
  final ordered = <Workout>[];
  final seen = <String>{};
  _takeInOrder(ordered, seen, byId, order.primary);
  _takeInOrder(ordered, seen, byId, order.secondary);
  for (final workout in kept) {
    if (seen.add(workout.id)) {
      ordered.add(workout);
    }
  }
  return ordered;
}

void _takeInOrder(
  List<Workout> ordered,
  Set<String> seen,
  Map<String, Workout> byId,
  List<Workout> source,
) {
  for (final workout in source) {
    final match = byId[workout.id];
    if (match != null && seen.add(match.id)) {
      ordered.add(match);
    }
  }
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

class _SessionMerge {
  const _SessionMerge({required this.sessions, required this.deletions});

  final List<CompletedSession> sessions;
  final List<WorkoutDeletion> deletions;
}

_SessionMerge _mergeSessions(AccountSnapshot local, AccountSnapshot remote) {
  final deletions = <String, DateTime>{};
  _keepDeletions(deletions, local.deletedSessions);
  _keepDeletions(deletions, remote.deletedSessions);

  final byId = <String, CompletedSession>{};
  for (final session in [...local.sessions, ...remote.sessions]) {
    final existing = byId[session.id];
    byId[session.id] = existing == null
        ? session
        : _sharedSetLogs(existing, session);
  }

  final keptSessions = <CompletedSession>[];
  final keptDeletions = <WorkoutDeletion>[];
  for (final id in {...byId.keys, ...deletions.keys}) {
    final deletedAt = deletions[id];
    if (deletedAt != null) {
      keptDeletions.add(WorkoutDeletion(id: id, deletedAt: deletedAt));
      continue;
    }
    final session = byId[id];
    if (session != null) {
      keptSessions.add(session);
    }
  }
  keptSessions.sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return _SessionMerge(sessions: keptSessions, deletions: keptDeletions);
}

/// Keeps set logs that both copies still have, matched on exercise, round, and set.
CompletedSession _sharedSetLogs(
  CompletedSession first,
  CompletedSession second,
) {
  final kept = [
    for (final log in first.setLogs)
      if (_hasSameSet(second, log)) log,
  ];
  if (kept.length == first.setLogs.length) {
    return first;
  }
  return CompletedSession(
    id: first.id,
    workoutId: first.workoutId,
    workoutName: first.workoutName,
    completedAt: first.completedAt,
    durationSeconds: first.durationSeconds,
    totalExercises: first.totalExercises,
    setLogs: kept,
  );
}

bool _hasSameSet(CompletedSession session, SetLog log) {
  for (final other in session.setLogs) {
    if (other.exerciseId == log.exerciseId &&
        other.round == log.round &&
        other.setNumber == log.setNumber) {
      return true;
    }
  }
  return false;
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
