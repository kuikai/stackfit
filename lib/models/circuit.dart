import 'exercise.dart';

/// Exercises that play in order, then repeat for [rounds].
class Circuit {
  const Circuit({
    required this.id,
    required this.rounds,
    required this.restBetweenRoundsSeconds,
    required this.exercises,
  });

  final String id;
  final int rounds;
  final int restBetweenRoundsSeconds;
  final List<Exercise> exercises;

  Circuit copyWith({
    String? id,
    int? rounds,
    int? restBetweenRoundsSeconds,
    List<Exercise>? exercises,
  }) {
    return Circuit(
      id: id ?? this.id,
      rounds: rounds ?? this.rounds,
      restBetweenRoundsSeconds:
          restBetweenRoundsSeconds ?? this.restBetweenRoundsSeconds,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'circuit',
      'id': id,
      'rounds': rounds,
      'restBetweenRoundsSeconds': restBetweenRoundsSeconds,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
    };
  }

  factory Circuit.fromJson(Map<String, dynamic> json) {
    final rounds = (json['rounds'] as num?)?.toInt() ?? 1;
    final rest = (json['restBetweenRoundsSeconds'] as num?)?.toInt() ?? 0;
    final rawExercises = json['exercises'];
    return Circuit(
      id: json['id'] as String? ?? '',
      rounds: rounds < 1 ? 1 : rounds,
      restBetweenRoundsSeconds: rest < 0 ? 0 : rest,
      exercises: _exercisesFromJson(rawExercises),
    );
  }
}

/// One slot in a workout: a single exercise, or a circuit.
sealed class WorkoutBlock {
  const WorkoutBlock();

  List<Exercise> get exercises;

  WorkoutBlock withFreshIds(String Function() newId);

  Map<String, dynamic> toJson();

  factory WorkoutBlock.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'circuit') {
      return CircuitBlock(Circuit.fromJson(json));
    }
    final nested = json['exercise'];
    if (nested is Map) {
      return ExerciseBlock(
        Exercise.fromJson(Map<String, dynamic>.from(nested)),
      );
    }
    return ExerciseBlock(Exercise.fromJson(json));
  }
}

List<Exercise> _exercisesFromJson(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return [
    for (final item in raw)
      if (item is Map) Exercise.fromJson(Map<String, dynamic>.from(item)),
  ];
}

/// A normal exercise that runs once.
class ExerciseBlock extends WorkoutBlock {
  const ExerciseBlock(this.exercise);

  final Exercise exercise;

  @override
  List<Exercise> get exercises => [exercise];

  @override
  WorkoutBlock withFreshIds(String Function() newId) {
    return ExerciseBlock(exercise.copyWith(id: newId()));
  }

  @override
  Map<String, dynamic> toJson() {
    return {'type': 'exercise', 'exercise': exercise.toJson()};
  }
}

/// A circuit box inside a workout.
class CircuitBlock extends WorkoutBlock {
  const CircuitBlock(this.circuit);

  final Circuit circuit;

  @override
  List<Exercise> get exercises => circuit.exercises;

  @override
  WorkoutBlock withFreshIds(String Function() newId) {
    return CircuitBlock(
      circuit.copyWith(
        id: newId(),
        exercises: [
          for (final exercise in circuit.exercises)
            exercise.copyWith(id: newId()),
        ],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => circuit.toJson();
}
