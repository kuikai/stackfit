import 'exercise.dart';
import 'exercise_type.dart';

class Workout {
  final String id;
  final String name;
  final List<Exercise> exercises;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional folder on Home, e.g. "Bro Split". Null means ungrouped.
  final String? section;

  const Workout({
    required this.id,
    required this.name,
    required this.exercises,
    required this.createdAt,
    required this.updatedAt,
    this.section,
  });

  Workout copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? section,
    bool clearSection = false,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      section: clearSection ? null : (section ?? this.section),
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
      if (section != null) 'section': section,
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
      section: normalizeSection(json['section'] as String?),
    );
  }

  /// Empty or whitespace is treated as ungrouped.
  static String? normalizeSection(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }
}

/// One block on Home: either a named section or a single ungrouped workout.
class WorkoutHomeGroup {
  const WorkoutHomeGroup({this.section, required this.workouts});

  final String? section;
  final List<Workout> workouts;

  bool get isSection => section != null;
}

/// Keeps list order. Workouts that share a section gather at the first one.
List<WorkoutHomeGroup> groupWorkoutsForHome(List<Workout> workouts) {
  final groups = <WorkoutHomeGroup>[];
  final sectionIndex = <String, int>{};

  for (final workout in workouts) {
    final section = workout.section;
    if (section == null) {
      groups.add(WorkoutHomeGroup(section: null, workouts: [workout]));
      continue;
    }
    final existing = sectionIndex[section];
    if (existing == null) {
      sectionIndex[section] = groups.length;
      groups.add(WorkoutHomeGroup(section: section, workouts: [workout]));
    } else {
      groups[existing].workouts.add(workout);
    }
  }
  return groups;
}
