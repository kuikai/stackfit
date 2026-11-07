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

/// One point on the load chart. [value] is kilograms or reps.
class HistoryChartPoint {
  const HistoryChartPoint({required this.at, required this.value});

  final DateTime at;
  final double value;
}

enum HistoryChartUnit { kilograms, reps }

/// Load over time for one workout. Points run oldest to newest.
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

/// Kilograms when at least two sessions logged weight. Otherwise reps.
/// One session, or none, has nothing to draw.
HistoryChartSeries? historyChartSeries(List<CompletedSession> sessions) {
  if (sessions.length < 2) {
    return null;
  }
  final useKilograms = _weightedSessionCount(sessions) >= 2;
  final ordered = [...sessions]
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  return HistoryChartSeries(
    unit: useKilograms ? HistoryChartUnit.kilograms : HistoryChartUnit.reps,
    points: [
      for (final session in ordered)
        HistoryChartPoint(
          at: session.completedAt,
          value: useKilograms
              ? session.totalVolumeKg
              : session.totalRepsLogged.toDouble(),
        ),
    ],
  );
}

int _weightedSessionCount(List<CompletedSession> sessions) {
  var count = 0;
  for (final session in sessions) {
    if (session.totalVolumeKg > 0) {
      count += 1;
    }
  }
  return count;
}
