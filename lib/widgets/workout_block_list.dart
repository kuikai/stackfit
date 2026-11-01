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
    required this.onMoveBlock,
    required this.onEditExercise,
    required this.onDeleteBlock,
    required this.onCircuitChanged,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
    required this.onReorderStation,
    required this.onMoveStation,
  });

  final List<WorkoutBlock> blocks;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index, int direction) onMoveBlock;
  final ValueChanged<int> onEditExercise;
  final ValueChanged<int> onDeleteBlock;
  final void Function(String circuitId, Circuit circuit) onCircuitChanged;
  final ValueChanged<String> onAddStation;
  final void Function(String circuitId, int stationIndex) onEditStation;
  final void Function(String circuitId, int stationIndex) onDeleteStation;
  final void Function(String circuitId, int oldIndex, int newIndex)
  onReorderStation;
  final void Function(String circuitId, int stationIndex, int direction)
  onMoveStation;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: EdgeInsets.zero,
      itemCount: blocks.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final block = blocks[index];
        final moveUp = index == 0 ? null : () => onMoveBlock(index, -1);
        final moveDown = index == blocks.length - 1
            ? null
            : () => onMoveBlock(index, 1);
        return switch (block) {
          ExerciseBlock(:final exercise) => ReorderableDelayedDragStartListener(
            key: ValueKey(exercise.id),
            index: index,
            child: ExerciseEditorTile(
              exercise: exercise,
              onEdit: () => onEditExercise(index),
              onDelete: () => onDeleteBlock(index),
              onMoveUp: moveUp,
              onMoveDown: moveDown,
            ),
          ),
          CircuitBlock(:final circuit) => _CircuitCard(
            key: ValueKey(circuit.id),
            index: index,
            circuit: circuit,
            onChanged: (next) => onCircuitChanged(circuit.id, next),
            onDelete: () => onDeleteBlock(index),
            onMoveUp: moveUp,
            onMoveDown: moveDown,
            onAddStation: () => onAddStation(circuit.id),
            onEditStation: (station) => onEditStation(circuit.id, station),
            onDeleteStation: (station) => onDeleteStation(circuit.id, station),
            onReorderStation: (oldIndex, newIndex) =>
                onReorderStation(circuit.id, oldIndex, newIndex),
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
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
    required this.onReorderStation,
    required this.onMoveStation,
  });

  final int index;
  final Circuit circuit;
  final ValueChanged<Circuit> onChanged;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onAddStation;
  final ValueChanged<int> onEditStation;
  final ValueChanged<int> onDeleteStation;
  final void Function(int oldIndex, int newIndex) onReorderStation;
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
            _CircuitHeader(
              index: index,
              onDelete: onDelete,
              onMoveUp: onMoveUp,
              onMoveDown: onMoveDown,
            ),
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
                    min: 1,
                    max: 99,
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
                    max: 600,
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
            if (circuit.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Add the exercises that repeat.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              )
            else
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                padding: EdgeInsets.zero,
                itemCount: circuit.exercises.length,
                onReorder: onReorderStation,
                itemBuilder: (context, station) {
                  final exercise = circuit.exercises[station];
                  return ReorderableDelayedDragStartListener(
                    key: ValueKey(exercise.id),
                    index: station,
                    child: ExerciseEditorTile(
                      exercise: exercise,
                      onEdit: () => onEditStation(station),
                      onDelete: () => onDeleteStation(station),
                      onMoveUp: station == 0
                          ? null
                          : () => onMoveStation(station, -1),
                      onMoveDown: station == circuit.exercises.length - 1
                          ? null
                          : () => onMoveStation(station, 1),
                    ),
                  );
                },
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
  const _CircuitHeader({
    required this.index,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final int index;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ReorderableDelayedDragStartListener(
      index: index,
      child: Row(
        children: [
          EditorMoveButton(
            tooltip: 'Move up',
            icon: Icons.keyboard_arrow_up_rounded,
            onPressed: onMoveUp,
          ),
          EditorMoveButton(
            tooltip: 'Move down',
            icon: Icons.keyboard_arrow_down_rounded,
            onPressed: onMoveDown,
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
      ),
    );
  }
}
