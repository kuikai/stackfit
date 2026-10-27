import 'set_log.dart';

class CompletedSession {
  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime completedAt;
  final int durationSeconds;
  final int totalExercises;

  /// Reps logged per set during the session. Empty for timer-only workouts
  /// and for sessions saved before logging existed.
  final List<SetLog> setLogs;

  const CompletedSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.completedAt,
    required this.durationSeconds,
    required this.totalExercises,
    this.setLogs = const [],
  });

  bool get hasSetLogs => setLogs.isNotEmpty;

  /// This session with one exercise's sets removed (one circuit round).
  CompletedSession withoutExerciseLog({
    required String exerciseId,
    required int round,
  }) {
    return CompletedSession(
      id: id,
      workoutId: workoutId,
      workoutName: workoutName,
      completedAt: completedAt,
      durationSeconds: durationSeconds,
      totalExercises: totalExercises,
      setLogs: [
        for (final log in setLogs)
          if (log.exerciseId != exerciseId || log.round != round) log,
      ],
    );
  }

  /// Total reps across every logged set.
  int get totalRepsLogged {
    var total = 0;
    for (final log in setLogs) {
      total += log.reps;
    }
    return total;
  }

  /// Sum of reps × kg over weighted sets; 0 when nothing was weighted.
  double get totalVolumeKg {
    var total = 0.0;
    for (final log in setLogs) {
      if (log.hasWeight) {
        total += log.reps * log.weightKg!;
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'workoutName': workoutName,
      'completedAt': completedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'totalExercises': totalExercises,
      if (setLogs.isNotEmpty)
        'setLogs': setLogs.map((log) => log.toJson()).toList(),
    };
  }

  factory CompletedSession.fromJson(Map<String, dynamic> json) {
    return CompletedSession(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      workoutName: json['workoutName'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      durationSeconds: json['durationSeconds'] as int,
      totalExercises: json['totalExercises'] as int,
      setLogs: SetLog.listFromJson(json['setLogs']),
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }
}
