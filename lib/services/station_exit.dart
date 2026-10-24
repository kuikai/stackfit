import '../models/models.dart';

/// Where the runner goes after the current station is finished.
enum StationDestination { station, round, block }

/// Rest to play, then [destination]. A rest of 0 means go there immediately.
class StationExit {
  const StationExit({required this.destination, required this.restSeconds});

  final StationDestination destination;
  final int restSeconds;
}

/// Plans the gap after one station.
///
/// [restAfterLastSet] is true for a sets exercise, which already rests after
/// its last set before the next exercise. A timer skips that trailing rest,
/// except between stations of a circuit, where its rest is the gap.
StationExit planStationExit({
  required Workout workout,
  required int blockIndex,
  required int roundIndex,
  required int exerciseIndex,
  required bool restAfterLastSet,
}) {
  if (blockIndex < 0 || blockIndex >= workout.blocks.length) {
    return const StationExit(
      destination: StationDestination.block,
      restSeconds: 0,
    );
  }
  final block = workout.blocks[blockIndex];
  final exercise = _exerciseAt(block, exerciseIndex);
  final stationRest = _nonNegative(
    restAfterLastSet ? exercise?.restSeconds ?? 0 : 0,
  );

  if (block is! CircuitBlock) {
    return StationExit(
      destination: StationDestination.block,
      restSeconds: stationRest,
    );
  }

  final circuit = block.circuit;
  final lastStation = exerciseIndex >= circuit.exercises.length - 1;
  final rounds = circuit.rounds < 1 ? 1 : circuit.rounds;
  if (!lastStation) {
    return StationExit(
      destination: StationDestination.station,
      restSeconds: _nonNegative(exercise?.restSeconds ?? 0),
    );
  }
  if (roundIndex < rounds - 1) {
    return StationExit(
      destination: StationDestination.round,
      restSeconds: _nonNegative(circuit.restBetweenRoundsSeconds),
    );
  }
  return StationExit(
    destination: StationDestination.block,
    restSeconds: stationRest,
  );
}

Exercise? _exerciseAt(WorkoutBlock block, int exerciseIndex) {
  return switch (block) {
    ExerciseBlock(:final exercise) => exerciseIndex == 0 ? exercise : null,
    CircuitBlock(:final circuit) =>
      exerciseIndex < 0 || exerciseIndex >= circuit.exercises.length
          ? null
          : circuit.exercises[exerciseIndex],
  };
}

int _nonNegative(int value) => value < 0 ? 0 : value;
