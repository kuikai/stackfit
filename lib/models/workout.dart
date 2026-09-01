import 'exercise.dart';
import 'exercise_type.dart';

class Workout {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Workout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
  });

  Workout copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Total estimated duration in seconds (rough)
  int get estimatedDurationSeconds {
    int total = 0;
    for (final e in exercises) {
      if (e.type == ExerciseType.timer) {
        final rounds = e.sets ?? 1;
        total += ((e.workSeconds ?? 0) + (e.restSeconds ?? 0)) * rounds;
      } else {
        final sets = e.sets ?? 1;
        // Assume ~45s per set of work + rest between sets
        total += (sets * 45) + ((sets - 1) * (e.restSeconds ?? 0));
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
