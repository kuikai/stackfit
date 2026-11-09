import 'completed_session.dart';

/// Finished sessions of one workout, newest first.
class HistoryWorkoutGroup {
  const HistoryWorkoutGroup({
    required this.workoutId,
    required this.name,
    required this.sessions,
  });

  final String workoutId;

  /// Name on the newest session, so a rename stays on this workout.
  final String name;

  final List<CompletedSession> sessions;
}

/// One point on the load chart. [value] is kilograms, a set count, or seconds.
class HistoryChartPoint {
  const HistoryChartPoint({required this.at, required this.value});

  final DateTime at;
  final double value;
}

enum HistoryChartUnit { kilograms, sets, seconds }

/// One exercise that can be drawn on the load chart.
class HistoryChartExercise {
  const HistoryChartExercise({required this.id, required this.name});

  final String id;

  /// Name on the newest log of this exercise.
  final String name;
}

/// Load over time for one workout, or one exercise in it.
/// Points run oldest to newest.
class HistoryChartSeries {
  const HistoryChartSeries({required this.unit, required this.points});

  final HistoryChartUnit unit;
  final List<HistoryChartPoint> points;
}

/// Groups [sessions] by workout. Newest workout first, newest session first.
List<HistoryWorkoutGroup> groupSessionsByWorkout(
  List<CompletedSession> sessions,
) {
  final byId = <String, List<CompletedSession>>{};
  for (final session in sessions) {
    byId.putIfAbsent(session.workoutId, () => []).add(session);
  }
  final groups = [
    for (final entry in byId.entries) _groupFor(entry.key, entry.value),
  ];
  groups.sort(
    (a, b) =>
        b.sessions.first.completedAt.compareTo(a.sessions.first.completedAt),
  );
  return groups;
}

HistoryWorkoutGroup _groupFor(
  String workoutId,
  List<CompletedSession> sessions,
) {
  final ordered = [...sessions]
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  return HistoryWorkoutGroup(
    workoutId: workoutId,
    name: ordered.first.workoutName,
    sessions: ordered,
  );
}

/// Exercises that appear in [sessions], newest session first.
/// The same exercise id is listed once, under the name on its newest log.
List<HistoryChartExercise> historyChartExercises(
  List<CompletedSession> sessions,
) {
  final newestFirst = [...sessions]
    ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  final seen = <String>{};
  final exercises = <HistoryChartExercise>[];
  for (final session in newestFirst) {
    for (final log in session.setLogs) {
      if (!seen.add(log.exerciseId)) {
        continue;
      }
      exercises.add(
        HistoryChartExercise(id: log.exerciseId, name: log.exerciseName),
      );
    }
  }
  return exercises;
}

/// True when every logged set is a hold, and there is at least one.
bool historyLogsAreHolds(
  List<CompletedSession> sessions, {
  String? exerciseId,
}) {
  var any = false;
  for (final session in sessions) {
    for (final log in session.setLogs) {
      if (exerciseId != null && log.exerciseId != exerciseId) {
        continue;
      }
      if (!log.isHold) {
        return false;
      }
      any = true;
    }
  }
  return any;
}

/// Kilograms, set count, or seconds held. [exerciseId] null is the whole workout.
/// A chosen exercise leaves out sessions that did not log it.
/// Fewer than two points has nothing to draw.
HistoryChartSeries? historyChartSeries(
  List<CompletedSession> sessions, {
  String? exerciseId,
  HistoryChartUnit unit = HistoryChartUnit.kilograms,
}) {
  final matching = [
    for (final session in sessions)
      if (exerciseId == null || _loggedExercise(session, exerciseId)) session,
  ];
  if (matching.length < 2) {
    return null;
  }
  final ordered = [...matching]
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  return HistoryChartSeries(
    unit: unit,
    points: [
      for (final session in ordered)
        HistoryChartPoint(
          at: session.completedAt,
          value: _chartValue(session, exerciseId: exerciseId, unit: unit),
        ),
    ],
  );
}

bool _loggedExercise(CompletedSession session, String exerciseId) {
  for (final log in session.setLogs) {
    if (log.exerciseId == exerciseId) {
      return true;
    }
  }
  return false;
}

double _chartValue(
  CompletedSession session, {
  required String? exerciseId,
  required HistoryChartUnit unit,
}) {
  if (unit == HistoryChartUnit.seconds) {
    return _longestHold(session, exerciseId).toDouble();
  }
  if (exerciseId == null) {
    return unit == HistoryChartUnit.kilograms
        ? session.totalVolumeKg
        : session.setLogs.length.toDouble();
  }
  if (unit == HistoryChartUnit.sets) {
    var count = 0;
    for (final log in session.setLogs) {
      if (log.exerciseId == exerciseId) {
        count += 1;
      }
    }
    return count.toDouble();
  }
  var volume = 0.0;
  for (final log in session.setLogs) {
    if (log.exerciseId == exerciseId && log.hasWeight) {
      volume += log.reps * log.weightKg!;
    }
  }
  return volume;
}

int _longestHold(CompletedSession session, String? exerciseId) {
  var best = 0;
  for (final log in session.setLogs) {
    if (exerciseId != null && log.exerciseId != exerciseId) {
      continue;
    }
    final held = log.heldSeconds;
    if (held != null && held > best) {
      best = held;
    }
  }
  return best;
}
