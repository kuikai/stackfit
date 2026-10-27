import '../models/completed_session.dart';
import '../models/set_log.dart';

/// Reps and weight from the last time [exerciseId] was logged in [workoutId].
///
/// [sessions] is newest first. A match is the same exercise id and [round].
/// When that id was never logged in this workout, the same exercise name is
/// used instead, so an exercise that was removed and added again still shows
/// last time.
List<SetLog> previousLogsForExercise({
  required List<CompletedSession> sessions,
  required String workoutId,
  required String exerciseId,
  required String exerciseName,
  int round = 1,
}) {
  final forWorkout = [
    for (final session in sessions)
      if (session.workoutId == workoutId) session,
  ];
  final byId = _newestMatch(
    forWorkout,
    round: round,
    matches: (log) => log.exerciseId == exerciseId,
  );
  if (byId.isNotEmpty) {
    return byId;
  }
  if (_idWasLogged(forWorkout, exerciseId)) {
    return const [];
  }
  return _newestMatch(
    forWorkout,
    round: round,
    matches: (log) => log.exerciseName == exerciseName,
  );
}

/// Sets from the newest session that has a log for [round] matching [matches].
List<SetLog> _newestMatch(
  List<CompletedSession> sessions, {
  required int round,
  required bool Function(SetLog log) matches,
}) {
  for (final session in sessions) {
    final logs = [
      for (final log in session.setLogs)
        if (log.round == round && matches(log)) log,
    ];
    if (logs.isNotEmpty) {
      return logs;
    }
  }
  return const [];
}

/// Reps and kg to put in the steppers for the set being added.
class StartingSetEntry {
  const StartingSetEntry({required this.reps, required this.weightKg});

  final int reps;
  final double weightKg;
}

/// What to show when adding [setNumber].
///
/// Uses that set from [previousLogs] when last time has it. Otherwise uses
/// the plan's [plannedReps] and the weight already used earlier in this
/// session.
StartingSetEntry startingEntryForSet({
  required List<SetLog> previousLogs,
  required int setNumber,
  required int? plannedReps,
  required double sessionWeightKg,
}) {
  for (final log in previousLogs) {
    if (log.setNumber != setNumber) {
      continue;
    }
    return StartingSetEntry(reps: log.reps, weightKg: log.weightKg ?? 0);
  }
  return StartingSetEntry(reps: plannedReps ?? 0, weightKg: sessionWeightKg);
}

bool _idWasLogged(List<CompletedSession> sessions, String exerciseId) {
  for (final session in sessions) {
    for (final log in session.setLogs) {
      if (log.exerciseId == exerciseId) {
        return true;
      }
    }
  }
  return false;
}
