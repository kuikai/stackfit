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
  if (exercise.type == ExerciseType.hold) {
    final attempts = exercise.sets ?? 1;
    final gaps = attempts > 1 ? attempts - 1 : 0;
    final rest = exercise.restSeconds ?? 0;
    return gaps * (rest < 0 ? 0 : rest);
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

/// Moves the Home row at [from] so it lands at [to].
///
/// A row is one section or one ungrouped workout. Out-of-range indexes leave
/// the list as it is. Sections come out as contiguous blocks.
List<Workout> moveHomeGroup(List<Workout> workouts, int from, int to) {
  final groups = groupWorkoutsForHome(workouts);
  if (from < 0 ||
      to < 0 ||
      from >= groups.length ||
      to >= groups.length ||
      from == to) {
    return workouts;
  }
  final next = [...groups];
  final moved = next.removeAt(from);
  next.insert(to, moved);
  return _flattenHomeGroups(next);
}

/// Moves [workoutId] to slot [to] inside its section.
///
/// An ungrouped workout, or a [to] past either end, leaves the list as it is.
List<Workout> moveWorkoutInSectionTo(
  List<Workout> workouts,
  String workoutId,
  int to,
) {
  final groups = groupWorkoutsForHome(workouts);
  final next = <WorkoutHomeGroup>[];
  var changed = false;
  for (final group in groups) {
    final reordered = _moveInsideSection(group, workoutId, to);
    if (reordered == null) {
      next.add(group);
      continue;
    }
    next.add(reordered);
    changed = true;
  }
  if (!changed) {
    return workouts;
  }
  return _flattenHomeGroups(next);
}

/// Moves [workoutId] up or down inside its section.
///
/// [direction] is -1 or 1. An ungrouped workout, or a move past either end,
/// leaves the list as it is. Sections come out as contiguous blocks.
List<Workout> moveWorkoutInsideSection(
  List<Workout> workouts,
  String workoutId,
  int direction,
) {
  for (final group in groupWorkoutsForHome(workouts)) {
    if (!group.isSection) {
      continue;
    }
    final index = group.workouts.indexWhere(
      (workout) => workout.id == workoutId,
    );
    if (index >= 0) {
      return moveWorkoutInSectionTo(workouts, workoutId, index + direction);
    }
  }
  return workouts;
}

WorkoutHomeGroup? _moveInsideSection(
  WorkoutHomeGroup group,
  String workoutId,
  int to,
) {
  if (!group.isSection) {
    return null;
  }
  final index = group.workouts.indexWhere((workout) => workout.id == workoutId);
  if (index < 0 || to < 0 || to >= group.workouts.length || index == to) {
    return null;
  }
  final reordered = [...group.workouts];
  final moved = reordered.removeAt(index);
  reordered.insert(to, moved);
  return WorkoutHomeGroup(section: group.section, workouts: reordered);
}

List<Workout> _flattenHomeGroups(List<WorkoutHomeGroup> groups) {
  return [for (final group in groups) ...group.workouts];
}

/// Moves [workoutId] onto Home or into a folder at a specific slot.
///
/// When [section] is null, [index] is a Home row index (loose workout or
/// folder). When [section] is set, [index] is the day slot inside that folder
/// (0 = top, length = after the last day). Out-of-range indexes clamp.
List<Workout> placeWorkoutAt(
  List<Workout> workouts,
  String workoutId, {
  String? section,
  required int index,
  DateTime? updatedAt,
}) {
  final groups = groupWorkoutsForHome(workouts);
  Workout? moved;
  final next = <WorkoutHomeGroup>[];

  for (final group in groups) {
    if (!group.isSection) {
      final workout = group.workouts.single;
      if (workout.id == workoutId) {
        moved = workout;
        continue;
      }
      next.add(group);
      continue;
    }

    final kept = <Workout>[];
    for (final workout in group.workouts) {
      if (workout.id == workoutId) {
        moved = workout;
      } else {
        kept.add(workout);
      }
    }
    if (kept.isEmpty) {
      continue;
    }
    next.add(WorkoutHomeGroup(section: group.section, workouts: kept));
  }

  if (moved == null) {
    return workouts;
  }

  final normalized = Workout.normalizeSection(section);
  final placed = moved.copyWith(
    section: normalized,
    clearSection: normalized == null,
    updatedAt: updatedAt ?? moved.updatedAt,
  );

  if (normalized == null) {
    final at = index.clamp(0, next.length);
    next.insert(at, WorkoutHomeGroup(section: null, workouts: [placed]));
    return _flattenHomeGroups(next);
  }

  final sectionIndex = next.indexWhere((group) => group.section == normalized);
  if (sectionIndex < 0) {
    final at = index.clamp(0, next.length);
    next.insert(
      at,
      WorkoutHomeGroup(section: normalized, workouts: [placed]),
    );
    return _flattenHomeGroups(next);
  }

  final days = [...next[sectionIndex].workouts];
  final at = index.clamp(0, days.length);
  days.insert(at, placed);
  next[sectionIndex] = WorkoutHomeGroup(section: normalized, workouts: days);
  return _flattenHomeGroups(next);
}

/// One row in the flat Home list (folder header or a workout / day).
sealed class HomeFlatRow {
  const HomeFlatRow();

  String get key;
}

/// Folder header. When the folder is closed, [workouts] still holds its days.
class HomeFlatHeader extends HomeFlatRow {
  const HomeFlatHeader({required this.section, required this.workouts});

  final String section;
  final List<Workout> workouts;

  @override
  String get key => 's:$section';
}

/// A loose Home workout, or one day inside an open folder.
class HomeFlatWorkout extends HomeFlatRow {
  const HomeFlatWorkout({required this.workout, this.section});

  final Workout workout;

  /// Folder this day belongs to. Null means a loose Home row.
  final String? section;

  /// Stable across join/leave so a drop does not rebuild the tile as new.
  @override
  String get key => 'w:${workout.id}';
}

/// Drop target under an open folder so a workout can land on Home below it.
///
/// Without this row, a plan at the bottom of Home has no slot past its last
/// day — every release lands inside the plan.
class HomeFlatExit extends HomeFlatRow {
  const HomeFlatExit(this.section);

  final String section;

  @override
  String get key => 'x:$section';
}

/// Builds the flat Home rows. Open folders expand their days under the header.
List<HomeFlatRow> buildHomeFlatRows(
  List<WorkoutHomeGroup> groups,
  Set<String> openSections,
) {
  final rows = <HomeFlatRow>[];
  for (final group in groups) {
    if (!group.isSection) {
      rows.add(HomeFlatWorkout(workout: group.workouts.single));
      continue;
    }
    final section = group.section!;
    rows.add(HomeFlatHeader(section: section, workouts: group.workouts));
    if (openSections.contains(section)) {
      for (final workout in group.workouts) {
        rows.add(HomeFlatWorkout(workout: workout, section: section));
      }
      rows.add(HomeFlatExit(section));
    }
  }
  return rows;
}

/// Applies a flat-list drag so gaps inside an open folder work like Home.
///
/// [from]/to] are [onReorderItem] indexes. Moving a closed folder header
/// moves the whole folder among Home rows. Moving a workout joins, leaves, or
/// reorders days based on the slot it lands in. Dropping on a folder's exit
/// row parks the workout on Home under that folder.
List<Workout> reorderHomeFlatRows(
  List<Workout> workouts,
  Set<String> openSections,
  int from,
  int to,
) {
  final groups = groupWorkoutsForHome(workouts);
  final rows = buildHomeFlatRows(groups, openSections);
  if (from < 0 ||
      to < 0 ||
      from >= rows.length ||
      to >= rows.length ||
      from == to) {
    return workouts;
  }

  final moved = rows[from];
  if (moved is HomeFlatExit) {
    return workouts;
  }
  final without = [...rows]..removeAt(from);

  if (moved is HomeFlatHeader) {
    final groupFrom = groups.indexWhere((group) => group.section == moved.section);
    if (groupFrom < 0) {
      return workouts;
    }
    final groupTo = _homeGroupIndexForInsert(without, to);
    return moveHomeGroup(workouts, groupFrom, groupTo);
  }

  if (moved is! HomeFlatWorkout) {
    return workouts;
  }

  final section = _sectionForInsert(
    without,
    to,
    movingFromSection: moved.section,
  );
  if (section != null) {
    return placeWorkoutAt(
      workouts,
      moved.workout.id,
      section: section,
      index: _dayIndexForInsert(without, to, section),
    );
  }
  return placeWorkoutAt(
    workouts,
    moved.workout.id,
    section: null,
    index: _homeGroupIndexForInsert(without, to),
  );
}

/// Which folder a drop slot belongs to, if any.
///
/// A slot after the last day of a folder (before its exit row) is ambiguous:
/// "last day in the plan" or "loose row under the plan". Outsiders land under
/// the plan; a day that already belongs there stays as the last day.
String? _sectionForInsert(
  List<HomeFlatRow> rows,
  int insertAt, {
  String? movingFromSection,
}) {
  final HomeFlatRow? above = insertAt > 0 ? rows[insertAt - 1] : null;
  final HomeFlatRow? below =
      insertAt < rows.length ? rows[insertAt] : null;

  if (above is HomeFlatHeader) {
    return above.section;
  }
  if (above is HomeFlatWorkout && above.section != null) {
    final section = above.section!;
    if (below is HomeFlatWorkout && below.section == section) {
      return section;
    }
    // Before the exit row, or at end: outsiders leave; members stay last.
    if (below is HomeFlatExit || below == null) {
      return movingFromSection == section ? section : null;
    }
    if (movingFromSection == section) {
      return section;
    }
    return null;
  }
  if (below is HomeFlatWorkout && below.section != null) {
    return below.section;
  }
  return null;
}

int _dayIndexForInsert(List<HomeFlatRow> rows, int insertAt, String section) {
  var day = 0;
  for (var i = 0; i < insertAt && i < rows.length; i++) {
    final row = rows[i];
    if (row is HomeFlatWorkout && row.section == section) {
      day++;
    }
  }
  return day;
}

int _homeGroupIndexForInsert(List<HomeFlatRow> rows, int insertAt) {
  var home = 0;
  for (var i = 0; i < insertAt && i < rows.length; i++) {
    final row = rows[i];
    if (row is HomeFlatHeader || (row is HomeFlatWorkout && row.section == null)) {
      home++;
    }
  }
  return home;
}
