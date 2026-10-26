import 'circuit.dart';
import 'exercise.dart';
import 'set_log.dart';
import 'workout.dart';

/// A workout left before it finished. Kept on the phone so it can be continued.
///
/// This is not a history row and it is not part of the account snapshot.
class InProgressWorkout {
  const InProgressWorkout({
    required this.workout,
    required this.blockIndex,
    required this.roundIndex,
    required this.exerciseIndex,
    required this.setIndex,
    required this.phase,
    required this.remainingSeconds,
    required this.isPaused,
    required this.elapsedSeconds,
    required this.savedAt,
    this.origin,
    this.setLogs = const [],
    this.draftEdited = false,
    this.draftReps = 0,
    this.draftWeightKg = 0,
    this.afterRest,
  });

  final Workout workout;

  /// `plan:<plan id>:<day name>` when the run was started from the plan library.
  final String? origin;

  final int blockIndex;
  final int roundIndex;
  final int exerciseIndex;
  final int setIndex;

  /// `work`, `rest`, or `setReady`.
  final String phase;
  final int remainingSeconds;
  final bool isPaused;

  /// Seconds already spent. Time while the app was closed is not included.
  final int elapsedSeconds;
  final List<SetLog> setLogs;

  /// True when the open set's reps or weight were changed and not confirmed.
  final bool draftEdited;
  final int draftReps;
  final double draftWeightKg;

  /// What should happen when a saved rest ends: timerRound, set, station, round, block.
  final String? afterRest;
  final DateTime savedAt;

  static String planOrigin(String planId, String dayName) {
    return 'plan:$planId:$dayName';
  }

  bool get canResume {
    return phase == 'work' || phase == 'rest' || phase == 'setReady';
  }

  /// False at the first station with nothing logged and under a second elapsed.
  bool get hasProgress {
    if (setLogs.isNotEmpty || draftEdited) {
      return true;
    }
    if (blockIndex > 0 || roundIndex > 0 || exerciseIndex > 0 || setIndex > 0) {
      return true;
    }
    if (phase == 'rest') {
      return true;
    }
    return elapsedSeconds >= 1;
  }

  /// Same exercises, sets, and rounds. A rename still matches.
  bool matchesLayout(Workout current) {
    return workoutLayoutKey(workout) == workoutLayoutKey(current);
  }

  /// Clock start that keeps [elapsedSeconds] and ignores the gap while closed.
  DateTime resumedStartedAt(DateTime now) {
    final seconds = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    return now.subtract(Duration(seconds: seconds));
  }

  /// Changes that should be written. The ticking clock is not one of them.
  String get changeSignature {
    final logs = setLogs
        .map(
          (log) =>
              '${log.exerciseId}:${log.round}:${log.setNumber}:${log.reps}:${log.weightKg}',
        )
        .join(',');
    return '$blockIndex|$roundIndex|$exerciseIndex|$setIndex|$phase|$isPaused|'
        '$draftEdited|$draftReps|$draftWeightKg|$logs';
  }

  Map<String, dynamic> toJson() {
    return {
      'workout': workout.toJson(),
      if (origin != null) 'origin': origin,
      'blockIndex': blockIndex,
      'roundIndex': roundIndex,
      'exerciseIndex': exerciseIndex,
      'setIndex': setIndex,
      'phase': phase,
      'remainingSeconds': remainingSeconds,
      'isPaused': isPaused,
      'elapsedSeconds': elapsedSeconds,
      if (setLogs.isNotEmpty)
        'setLogs': setLogs.map((log) => log.toJson()).toList(),
      if (draftEdited) 'draftEdited': true,
      if (draftEdited) 'draftReps': draftReps,
      if (draftEdited) 'draftWeightKg': draftWeightKg,
      if (afterRest != null) 'afterRest': afterRest,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory InProgressWorkout.fromJson(Map<String, dynamic> json) {
    final workoutRaw = json['workout'];
    if (workoutRaw is! Map) {
      throw const FormatException('in-progress workout missing');
    }
    return InProgressWorkout(
      workout: Workout.fromJson(Map<String, dynamic>.from(workoutRaw)),
      origin: json['origin'] as String?,
      blockIndex: _nonNegative(json['blockIndex']),
      roundIndex: _nonNegative(json['roundIndex']),
      exerciseIndex: _nonNegative(json['exerciseIndex']),
      setIndex: _nonNegative(json['setIndex']),
      phase: json['phase'] as String? ?? 'work',
      remainingSeconds: _nonNegative(json['remainingSeconds']),
      isPaused: json['isPaused'] == true,
      elapsedSeconds: _nonNegative(json['elapsedSeconds']),
      setLogs: SetLog.listFromJson(json['setLogs']),
      draftEdited: json['draftEdited'] == true,
      draftReps: _nonNegative(json['draftReps']),
      draftWeightKg: (json['draftWeightKg'] as num?)?.toDouble() ?? 0,
      afterRest: json['afterRest'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

/// Identity of the stations, ignoring names and the Home section.
String workoutLayoutKey(Workout workout) {
  final parts = <String>[];
  for (final block in workout.blocks) {
    if (block is CircuitBlock) {
      parts.add(_circuitLayout(block.circuit));
      continue;
    }
    if (block is ExerciseBlock) {
      parts.add('e:${_exerciseLayout(block.exercise)}');
    }
  }
  return parts.join('|');
}

String _circuitLayout(Circuit circuit) {
  final stations = circuit.exercises.map(_exerciseLayout).join(',');
  return 'c:${circuit.id}:${circuit.rounds}:${circuit.restBetweenRoundsSeconds}:$stations';
}

String _exerciseLayout(Exercise exercise) {
  return '${exercise.id}:${exercise.type.name}:${exercise.sets}:'
      '${exercise.reps}:${exercise.workSeconds}:${exercise.restSeconds}';
}

int _nonNegative(Object? raw) {
  if (raw is! num) {
    return 0;
  }
  final value = raw.toInt();
  return value < 0 ? 0 : value;
}
