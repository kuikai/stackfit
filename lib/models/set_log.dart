/// Reps (and optional weight) actually performed for one set.
class SetLog {
  final String exerciseId;
  final String exerciseName;
  final int setNumber;
  final int reps;

  /// Load used, in kilograms. Null for bodyweight or when not entered.
  final double? weightKg;

  /// Seconds a hold lasted. Null for a reps set.
  final int? heldSeconds;

  /// Circuit round this set belongs to. 1 for a normal exercise.
  final int round;

  const SetLog({
    required this.exerciseId,
    required this.exerciseName,
    required this.setNumber,
    required this.reps,
    this.weightKg,
    this.heldSeconds,
    this.round = 1,
  });

  bool get hasWeight => weightKg != null && weightKg! > 0;

  bool get isHold => heldSeconds != null;

  SetLog copyWith({
    int? reps,
    double? weightKg,
    bool clearWeight = false,
    int? heldSeconds,
  }) {
    return SetLog(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      setNumber: setNumber,
      reps: reps ?? this.reps,
      weightKg: clearWeight ? null : (weightKg ?? this.weightKg),
      heldSeconds: heldSeconds ?? this.heldSeconds,
      round: round,
    );
  }

  /// "8", "8×60" (kg), or "1:05" for a hold.
  String get shortLabel {
    if (isHold) {
      return formatHeld(heldSeconds!);
    }
    return hasWeight ? '$reps×${formatKg(weightKg!)}' : '$reps';
  }

  /// Joins one exercise's sets, e.g. "8×60 · 8×60 · 6×60 kg", "12 · 10",
  /// or "1:05 · 0:48" for holds.
  static String summarize(List<SetLog> logs) {
    if (logs.isEmpty) {
      return '';
    }
    if (logs.every((log) => log.isHold)) {
      return logs.map((log) => log.shortLabel).join(' · ');
    }
    final hasWeight = logs.any((log) => log.hasWeight);
    final joined = logs.map((log) => log.shortLabel).join(' · ');
    return hasWeight ? '$joined kg' : joined;
  }

  /// 65 -> "1:05". Matches the clock on the workout screen.
  static String formatHeld(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$mm:$ss';
    }
    return '$minutes:$ss';
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
      if (heldSeconds != null) 'heldSeconds': heldSeconds,
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
      heldSeconds: (json['heldSeconds'] as num?)?.toInt(),
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
