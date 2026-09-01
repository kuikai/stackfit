import 'exercise_type.dart';

class Exercise {
  final String id;
  final String name;
  final ExerciseType type;

  /// Timer-based
  final int? workSeconds;
  final int? restSeconds;

  /// Set-based
  final int? sets;
  final int? reps; // optional

  const Exercise({
    required this.id,
    required this.name,
    required this.type,
    this.workSeconds,
    this.restSeconds,
    this.sets,
    this.reps,
  });

  /// Factory for Timer exercise.
  /// [sets] is the number of work/rest rounds (defaults to 1).
  factory Exercise.timer({
    required String id,
    required String name,
    required int workSeconds,
    required int restSeconds,
    int sets = 1,
  }) {
    return Exercise(
      id: id,
      name: name,
      type: ExerciseType.timer,
      workSeconds: workSeconds,
      restSeconds: restSeconds,
      sets: sets,
    );
  }

  /// Factory for Sets exercise
  factory Exercise.sets({
    required String id,
    required String name,
    required int sets,
    int? reps,
    required int restSeconds,
  }) {
    return Exercise(
      id: id,
      name: name,
      type: ExerciseType.sets,
      sets: sets,
      reps: reps,
      restSeconds: restSeconds,
    );
  }

  Exercise copyWith({
    String? id,
    String? name,
    ExerciseType? type,
    int? workSeconds,
    int? restSeconds,
    int? sets,
    int? reps,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'workSeconds': workSeconds,
      'restSeconds': restSeconds,
      'sets': sets,
      'reps': reps,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ExerciseType.fromString(json['type'] as String),
      workSeconds: json['workSeconds'] as int?,
      restSeconds: json['restSeconds'] as int?,
      sets: json['sets'] as int?,
      reps: json['reps'] as int?,
    );
  }

  @override
  String toString() {
    if (type == ExerciseType.timer) {
      final rounds = sets ?? 1;
      final roundsText = rounds > 1 ? ' · $rounds rounds' : '';
      return '$name (${workSeconds}s work / ${restSeconds}s rest$roundsText)';
    } else {
      final repsText = reps != null ? ' × $reps reps' : '';
      return '$name ($sets sets$repsText / ${restSeconds}s rest)';
    }
  }
}
