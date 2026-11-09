enum ExerciseType {
  timer,
  sets,
  hold;

  String get displayName {
    switch (this) {
      case ExerciseType.timer:
        return 'Timer';
      case ExerciseType.sets:
        return 'Sets';
      case ExerciseType.hold:
        return 'Hold';
    }
  }

  static ExerciseType fromString(String value) {
    return ExerciseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseType.timer,
    );
  }
}
