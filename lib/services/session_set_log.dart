import '../models/set_log.dart';

/// Reps and weight recorded while one workout is running.
class SessionSetLog {
  final List<SetLog> _logs = [];

  List<SetLog> get logs => List.unmodifiable(_logs);

  bool get isEmpty => _logs.isEmpty;

  SetLog? get last => _logs.isEmpty ? null : _logs.last;

  void clear() => _logs.clear();

  void replaceAll(List<SetLog> logs) {
    _logs
      ..clear()
      ..addAll(logs);
  }

  void add(SetLog log) => _logs.add(log);

  /// Returns false when there is no finished set, or [reps] is negative.
  bool updateLastReps(int reps) {
    if (_logs.isEmpty || reps < 0) {
      return false;
    }
    _logs[_logs.length - 1] = _logs.last.copyWith(reps: reps);
    return true;
  }

  /// Returns false when the set is missing or a value is negative.
  bool update(
    String exerciseId,
    int setNumber, {
    int? reps,
    double? weightKg,
    int round = 1,
  }) {
    if ((reps != null && reps < 0) || (weightKg != null && weightKg < 0)) {
      return false;
    }
    for (var index = 0; index < _logs.length; index++) {
      final log = _logs[index];
      if (log.exerciseId == exerciseId &&
          log.setNumber == setNumber &&
          log.round == round) {
        _logs[index] = log.copyWith(reps: reps, weightKg: weightKg);
        return true;
      }
    }
    return false;
  }

  List<SetLog> forExercise(String? exerciseId, {int? round}) {
    if (exerciseId == null) {
      return const [];
    }
    return _logs
        .where(
          (log) =>
              log.exerciseId == exerciseId &&
              (round == null || log.round == round),
        )
        .toList();
  }
}
