import '../exercise.dart';

/// Small builders used by the plan data files.
///
/// Ids are only placeholders: `PlanWorkoutBuilder` assigns fresh ids when a
/// plan day becomes a real workout, so these just need to be distinct.
class PlanExercises {
  PlanExercises._();

  static int _counter = 0;

  static String _nextId() {
    _counter += 1;
    return 'plan_exercise_$_counter';
  }

  /// Timer exercise. [work] and [rest] are seconds; [rounds] repeats both.
  static Exercise timer(
    String name, {
    required int work,
    int rest = 0,
    int rounds = 1,
  }) {
    return Exercise.timer(
      id: _nextId(),
      name: name,
      workSeconds: work,
      restSeconds: rest,
      sets: rounds,
    );
  }

  /// A single steady block measured in minutes (warm-up, tempo, cool-down).
  static Exercise block(String name, int minutes) {
    return timer(name, work: minutes * 60);
  }

  /// Set-based exercise. [reps] is optional (distance pieces use `null`).
  static Exercise sets(
    String name, {
    required int sets,
    int? reps,
    int rest = 90,
  }) {
    return Exercise.sets(
      id: _nextId(),
      name: name,
      sets: sets,
      reps: reps,
      restSeconds: rest,
    );
  }

  /// Expands a circuit into one timer exercise per station per round, so the
  /// app walks station 1..N, then starts round two. The last station of each
  /// round uses [roundRest] instead of [rest].
  static List<Exercise> circuit(
    List<String> stations, {
    required int work,
    required int rest,
    required int rounds,
    int? roundRest,
  }) {
    final result = <Exercise>[];
    for (var round = 0; round < rounds; round++) {
      for (var index = 0; index < stations.length; index++) {
        final isLastStation = index == stations.length - 1;
        final isLastRound = round == rounds - 1;
        var stationRest = rest;
        if (isLastStation) {
          stationRest = isLastRound ? 0 : (roundRest ?? rest);
        }
        result.add(timer(stations[index], work: work, rest: stationRest));
      }
    }
    return result;
  }
}
