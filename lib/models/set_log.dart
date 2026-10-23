/// Reps (and optional weight) actually performed for one set.
class SetLog {
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int reps;

  /// Load used, in kilograms. Null for bodyweight or when not entered.
  final double? weightKg;

  /// Circuit round this set belongs to. 1 for a normal exercise.
  final int round;

  const SetLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.round = 1,
  });

  bool get hasWeight => weightKg != null && weightKg! > 0;

  SetLog copyWith({int? reps, double? weightKg, bool clearWeight = false}) {
    return SetLog(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps ?? this.reps,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      round: round,
    );
  }

  /// "8" or "8×60" (kg), for compact summaries.
  String get shortLabel => hasWeight ? '$reps×${formatKg(weightKg!)}' : '$reps';

  /// Joins one exercise's sets, e.g. "8×60 · 8×60 · 6×60 kg" or "12 · 10".
  static String summarize(List<SetLog> logs) {
    if (logs.isEmpty) {
      return '';
    }
    final hasWeight = logs.any((log) => log.hasWeight);
    final joined = logs.map((log) => log.shortLabel).join(' · ');
    return hasWeight ? '$joined kg' : joined;
  }

  /// 60 -> "60", 62.5 -> "62.5".
  static String formatKg(double kg) {
    if (kg == kg.roundToDouble()) {
      return kg.toInt().toString();
    }
    return kg.toStringAsFixed(1);
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'exerciseName': exerciseName,
      'setNumber': setNumber,
      'reps': reps,
      if (weightKg != null) 'weightKg': weightKg,
      if (round > 1) 'round': round,
    };
  }

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      exerciseId: json['exerciseId'] as String? ?? '',
      exerciseName: json['exerciseName'] as String? ?? '',
      setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      round: (json['round'] as num?)?.toInt() ?? 1,
    );
  }

  /// Parses an optional list; missing or malformed data gives an empty list.
  static List<SetLog> listFromJson(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final result = <SetLog>[];
    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        result.add(SetLog.fromJson(item));
      }
    }
    return result;
  }
}
