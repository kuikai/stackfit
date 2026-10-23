import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/workout_block_list.dart';
import 'workout_editor_actions.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  const WorkoutEditorScreen({super.key, this.workoutId, this.initialSection});

  /// Null means create a new workout.
  final String? workoutId;

  /// Pre-fills the section when creating from a folder on Home.
  final String? initialSection;

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _sectionController;
  late String _workoutId;
  late DateTime _createdAt;
  late List<WorkoutBlock> _blocks;
  late bool _isNew;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existingId = widget.workoutId;
    final existing = existingId == null
        ? null
        : ref.read(workoutsProvider.notifier).byId(existingId);

    _isNew = existing == null;
    _workoutId = existing?.id ?? AppUtils.newId();
    _createdAt = existing?.createdAt ?? DateTime.now();
    _blocks = [...(existing?.blocks ?? const <WorkoutBlock>[])];
    _nameController = TextEditingController(text: existing?.name ?? '');
    _sectionController = TextEditingController(
      text: existing?.section ?? widget.initialSection ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New workout' : 'Edit workout'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: context.pageGutter(top: 8, bottom: 24),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Workout name',
              hintText: 'e.g. Push Day',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sectionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Section (optional)',
              hintText: 'e.g. Bro Split',
              helperText:
                  'Workouts with the same section sit together on Home.',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Exercises',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_blocks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                title: 'No exercises yet',
                message:
                    'Add an exercise, or a circuit that repeats a group of them.',
                icon: Icons.playlist_add_rounded,
              ),
            )
          else
            WorkoutBlockList(
              blocks: _blocks,
              onReorder: _onReorder,
              onEditExercise: _editExercise,
              onDeleteBlock: _removeBlock,
              onCircuitChanged: _updateCircuit,
              onAddStation: _addStation,
              onEditStation: _editStation,
              onDeleteStation: _deleteStation,
              onMoveStation: _moveStation,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: context.pageGutter(top: 8, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _showAddOptions,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add exercise'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_isNew ? 'Save workout' : 'Save changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      final item = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, item);
    });
  }

  Future<void> _showAddOptions() async {
    final choice = await askWhatToAdd(context);
    if (!mounted || choice == null) {
      return;
    }
    if (choice == WorkoutAddChoice.circuit) {
      setState(() => _blocks = [..._blocks, CircuitBlock(newCircuit())]);
      return;
    }
    final exercise = await pickExercise(
      context,
      fromCatalog: choice == WorkoutAddChoice.catalog,
    );
    if (!mounted || exercise == null) {
      return;
    }
    setState(() => _blocks = [..._blocks, ExerciseBlock(exercise)]);
  }

  Future<void> _editExercise(int index) async {
    final block = _blocks[index];
    if (block is! ExerciseBlock) {
      return;
    }
    final updated = await pickExercise(
      context,
      fromCatalog: false,
      initial: block.exercise,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _blocks = [
        for (var i = 0; i < _blocks.length; i++)
          if (i == index) ExerciseBlock(updated) else _blocks[i],
      ];
    });
  }

  void _removeBlock(int index) {
    setState(() {
      _blocks = [
        for (var i = 0; i < _blocks.length; i++)
          if (i != index) _blocks[i],
      ];
    });
  }

  void _updateCircuit(String circuitId, Circuit circuit) {
    setState(() => _blocks = mapCircuit(_blocks, circuitId, (_) => circuit));
  }

  Future<void> _addStation(String circuitId) async {
    final fromCatalog = await askStationSource(context);
    if (!mounted || fromCatalog == null) {
      return;
    }
    final exercise = await pickExercise(
      context,
      fromCatalog: fromCatalog,
      inCircuit: true,
    );
    if (!mounted || exercise == null) {
      return;
    }
    setState(() {
      _blocks = mapCircuit(_blocks, circuitId, (circuit) {
        return circuit.copyWith(exercises: [...circuit.exercises, exercise]);
      });
    });
  }

  Future<void> _editStation(String circuitId, int stationIndex) async {
    final circuit = circuitById(_blocks, circuitId);
    if (circuit == null || stationIndex >= circuit.exercises.length) {
      return;
    }
    final updated = await pickExercise(
      context,
      fromCatalog: false,
      initial: circuit.exercises[stationIndex],
      inCircuit: true,
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _blocks = mapCircuit(_blocks, circuitId, (current) {
        final stations = [...current.exercises];
        stations[stationIndex] = updated;
        return current.copyWith(exercises: stations);
      });
    });
  }

  void _deleteStation(String circuitId, int stationIndex) {
    setState(() {
      _blocks = mapCircuit(_blocks, circuitId, (circuit) {
        return circuit.copyWith(
          exercises: [
            for (var i = 0; i < circuit.exercises.length; i++)
              if (i != stationIndex) circuit.exercises[i],
          ],
        );
      });
    });
  }

  void _moveStation(String circuitId, int stationIndex, int direction) {
    setState(() {
      _blocks = mapCircuit(_blocks, circuitId, (circuit) {
        final next = stationIndex + direction;
        if (next < 0 || next >= circuit.exercises.length) {
          return circuit;
        }
        final stations = [...circuit.exercises];
        final station = stations.removeAt(stationIndex);
        stations.insert(next, station);
        return circuit.copyWith(exercises: stations);
      });
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _snack('Enter a workout name');
      return;
    }
    if (!_blocks.any((block) => block.exercises.isNotEmpty)) {
      _snack('Add at least one exercise');
      return;
    }
    if (_blocks.any(
      (block) => block is CircuitBlock && block.exercises.isEmpty,
    )) {
      _snack('Add at least one exercise to the circuit');
      return;
    }

    setState(() => _saving = true);
    final workout = Workout(
      id: _workoutId,
      name: name,
      blocks: List<WorkoutBlock>.unmodifiable(_blocks),
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      section: Workout.normalizeSection(_sectionController.text),
    );

    final notifier = ref.read(workoutsProvider.notifier);
    if (_isNew) {
      await notifier.addWorkout(workout);
    } else {
      await notifier.updateWorkout(workout);
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(workout);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
