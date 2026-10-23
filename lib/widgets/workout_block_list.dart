import 'package:flutter/material.dart';

import '../models/models.dart';
import 'exercise_editor_tile.dart';
import 'number_stepper.dart';

/// The workout editor list: loose exercises and circuit boxes.
class WorkoutBlockList extends StatelessWidget {
  const WorkoutBlockList({
    super.key,
    required this.blocks,
    required this.onReorder,
    required this.onEditExercise,
    required this.onDeleteBlock,
    required this.onCircuitChanged,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
    required this.onMoveStation,
  });

  final List<WorkoutBlock> blocks;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onEditExercise;
  final ValueChanged<int> onDeleteBlock;
  final void Function(String circuitId, Circuit circuit) onCircuitChanged;
  final ValueChanged<String> onAddStation;
  final void Function(String circuitId, int stationIndex) onEditStation;
  final void Function(String circuitId, int stationIndex) onDeleteStation;
  final void Function(String circuitId, int stationIndex, int direction)
  onMoveStation;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: blocks.length,
      onReorderItem: onReorder,
      itemBuilder: (context, index) {
        final block = blocks[index];
        return switch (block) {
          ExerciseBlock(:final exercise) => ExerciseEditorTile(
            key: ValueKey(exercise.id),
            exercise: exercise,
            index: index,
            onEdit: () => onEditExercise(index),
            onDelete: () => onDeleteBlock(index),
          ),
          CircuitBlock(:final circuit) => _CircuitCard(
            key: ValueKey(circuit.id),
            index: index,
            circuit: circuit,
            onChanged: (next) => onCircuitChanged(circuit.id, next),
            onDelete: () => onDeleteBlock(index),
            onAddStation: () => onAddStation(circuit.id),
            onEditStation: (station) => onEditStation(circuit.id, station),
            onDeleteStation: (station) => onDeleteStation(circuit.id, station),
            onMoveStation: (station, direction) =>
                onMoveStation(circuit.id, station, direction),
          ),
        };
      },
    );
  }
}

class _CircuitCard extends StatelessWidget {
  const _CircuitCard({
    super.key,
    required this.index,
    required this.circuit,
    required this.onChanged,
    required this.onDelete,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
    required this.onMoveStation,
  });

  final int index;
  final Circuit circuit;
  final ValueChanged<Circuit> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onAddStation;
  final ValueChanged<int> onEditStation;
  final ValueChanged<int> onDeleteStation;
  final void Function(int stationIndex, int direction) onMoveStation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: colorScheme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CircuitHeader(index: index, onDelete: onDelete),
            const SizedBox(height: 4),
            Text(
              'These exercises run in order, then repeat.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NumberStepper(
                    label: 'Rounds',
                    value: circuit.rounds.toDouble(),
                    onChanged: (value) => onChanged(
                      circuit.copyWith(
                        rounds: value.round().clamp(1, 99).toInt(),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: NumberStepper(
                    label: 'Rest between',
                    unit: 's',
                    value: circuit.restBetweenRoundsSeconds.toDouble(),
                    onChanged: (value) => onChanged(
                      circuit.copyWith(
                        restBetweenRoundsSeconds: value
                            .round()
                            .clamp(0, 600)
                            .toInt(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (var station = 0; station < circuit.exercises.length; station++)
              ExerciseEditorTile(
                exercise: circuit.exercises[station],
                index: station,
                draggable: false,
                onEdit: () => onEditStation(station),
                onDelete: () => onDeleteStation(station),
                onMoveUp: station == 0
                    ? null
                    : () => onMoveStation(station, -1),
                onMoveDown: station == circuit.exercises.length - 1
                    ? null
                    : () => onMoveStation(station, 1),
              ),
            if (circuit.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Add the exercises that repeat.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ),
            OutlinedButton.icon(
              onPressed: onAddStation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add station'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircuitHeader extends StatelessWidget {
  const _CircuitHeader({required this.index, required this.onDelete});

  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        ReorderableDragStartListener(
          index: index,
          child: Icon(
            Icons.drag_handle_rounded,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Circuit',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Remove circuit',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }
}
