import 'circuit.dart';
import 'exercise.dart';
import 'exercise_type.dart';

class Workout {
  final String id;
  final String name;

  /// Exercises and circuits, in the order they are played.
  final List<WorkoutBlock> blocks;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Optional folder on Home, e.g. "Bro Split". Null means ungrouped.
  final String? section;

  Workout({
    required this.id,
    required this.name,
    List<Exercise>? exercises,
    List<WorkoutBlock>? blocks,
    required this.createdAt,
    required this.updatedAt,
    this.section,
  }) : blocks =
           blocks ??
           [
             for (final exercise in exercises ?? const <Exercise>[])
               ExerciseBlock(exercise),
           ];

  /// Every station, with circuit stations listed once.
  List<Exercise> get exercises => [
    for (final block in blocks) ...block.exercises,
  ];

  bool get hasStations => exercises.isNotEmpty;

  int get circuitCount => blocks.whereType<CircuitBlock>().length;

  Workout copyWith({
    String? id,
    String? name,
    List<Exercise>? exercises,
    List<WorkoutBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? section,
    bool clearSection = false,
  }) {
    return Workout(
      id: id ?? this.id,
      name: name ?? this.name,
      blocks:
          blocks ??
          (exercises == null
              ? this.blocks
              : [for (final exercise in exercises) ExerciseBlock(exercise)]),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      section: clearSection ? null : (section ?? this.section),
    );
  }

  /// Total estimated duration in seconds (rough).
  int get estimatedDurationSeconds {
    var total = 0;
    for (final block in blocks) {
      if (block.exercises.isEmpty) {
        continue;
      }
      if (block is CircuitBlock) {
        total += _circuitDuration(block.circuit);
      } else {
        total += _exerciseDuration(block.exercises.first);
      }
    }
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (section != null) 'section': section,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      id: json['id'] as String,
      name: json['name'] as String,
      blocks: _blocksFromJson(json),
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

List<WorkoutBlock> _blocksFromJson(Map<String, dynamic> json) {
  final rawBlocks = json['blocks'];
  if (rawBlocks is List && rawBlocks.isNotEmpty) {
    return [
      for (final item in rawBlocks)
        if (item is Map) WorkoutBlock.fromJson(Map<String, dynamic>.from(item)),
    ];
  }
  final rawExercises = json['exercises'];
  if (rawExercises is! List) {
    return const [];
  }
  return [
    for (final item in rawExercises)
      if (item is Map)
        ExerciseBlock(Exercise.fromJson(Map<String, dynamic>.from(item))),
  ];
}

int _circuitDuration(Circuit circuit) {
  var once = 0;
  for (final exercise in circuit.exercises) {
    once += _exerciseDuration(exercise);
  }
  final rounds = circuit.rounds < 1 ? 1 : circuit.rounds;
  final between = circuit.restBetweenRoundsSeconds < 0
      ? 0
      : circuit.restBetweenRoundsSeconds;
  return once * rounds + between * (rounds - 1);
}

int _exerciseDuration(Exercise exercise) {
  if (exercise.type == ExerciseType.timer) {
    final rounds = exercise.sets ?? 1;
    return ((exercise.workSeconds ?? 0) + (exercise.restSeconds ?? 0)) * rounds;
  }
  final sets = exercise.sets ?? 1;
  final rest = (sets - 1) * (exercise.restSeconds ?? 0);
  return (sets * 45) + (rest < 0 ? 0 : rest);
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
