import '../models/models.dart';

enum SessionPhase {
  /// Timer exercise: work countdown.
  work,

  /// Rest countdown (after work or after a set).
  rest,

  /// Set exercise: waiting for user to tap Done.
  setReady,

  /// Workout finished.
  complete,
}

class WorkoutSessionState {
  const WorkoutSessionState({
    required this.workout,
    required this.blockIndex,
    required this.roundIndex,
    required this.exerciseIndex,
    required this.setIndex,
    required this.phase,
    required this.remainingSeconds,
    required this.isPaused,
    required this.startedAt,
  });

  final Workout workout;
  final int blockIndex;

  /// Round inside the current circuit. 0 for a normal exercise.
  final int roundIndex;

  /// Station inside the current block. 0 for a normal exercise.
  final int exerciseIndex;
  final int setIndex;
  final SessionPhase phase;
  final int remainingSeconds;
  final bool isPaused;
  final DateTime startedAt;

  WorkoutBlock? get currentBlock {
    if (blockIndex < 0 || blockIndex >= workout.blocks.length) {
      return null;
    }
    return workout.blocks[blockIndex];
  }

  Exercise? get currentExercise {
    final block = currentBlock;
    if (block is ExerciseBlock) {
      return exerciseIndex == 0 ? block.exercise : null;
    }
    if (block is CircuitBlock) {
      final stations = block.circuit.exercises;
      if (exerciseIndex < 0 || exerciseIndex >= stations.length) {
        return null;
      }
      return stations[exerciseIndex];
    }
    return null;
  }

  int get roundNumber => roundIndex + 1;

  /// "Exercise 2 of 4", or "Round 2 of 3 · Station 1 of 4" inside a circuit.
  String get progressLabel {
    final block = currentBlock;
    if (block is CircuitBlock) {
      final circuit = block.circuit;
      final stations = circuit.exercises.length;
      return 'Round $roundNumber of ${circuit.rounds}'
          ' · Station ${exerciseIndex + 1} of $stations';
    }
    final count = workout.blocks.length;
    final number = blockIndex + 1;
    return 'Exercise $number of $count';
  }

  int get setNumber => setIndex + 1;
  int get totalSets => currentExercise?.sets ?? 0;

  bool get isComplete => phase == SessionPhase.complete;

  int get elapsedSeconds {
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  WorkoutSessionState copyWith({
    int? blockIndex,
    int? roundIndex,
    int? exerciseIndex,
    int? setIndex,
    SessionPhase? phase,
    int? remainingSeconds,
    bool? isPaused,
  }) {
    return WorkoutSessionState(
      workout: workout,
      blockIndex: blockIndex ?? this.blockIndex,
      roundIndex: roundIndex ?? this.roundIndex,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      setIndex: setIndex ?? this.setIndex,
      phase: phase ?? this.phase,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isPaused: isPaused ?? this.isPaused,
      startedAt: startedAt,
    );
  }
}
