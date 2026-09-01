import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../../providers/workouts_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/exercise_editor_tile.dart';
import '../catalog/catalog_screen.dart';
import '../exercise_editor/exercise_editor_screen.dart';

class WorkoutEditorScreen extends ConsumerStatefulWidget {
  const WorkoutEditorScreen({
    super.key,
    this.workoutId,
  });

  /// Null means create a new workout.
  final String? workoutId;

  @override
  ConsumerState<WorkoutEditorScreen> createState() =>
      _WorkoutEditorScreenState();
}

class _WorkoutEditorScreenState extends ConsumerState<WorkoutEditorScreen> {
  late final TextEditingController _nameController;
  late String _workoutId;
  late DateTime _createdAt;
  late List<Exercise> _exercises;
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
    _exercises = [...(existing?.exercises ?? const <Exercise>[])];
    _nameController = TextEditingController(text: existing?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New workout' : 'Edit workout'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Workout name',
              hintText: 'e.g. Push Day',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Exercises',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (_exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: EmptyState(
                title: 'No exercises yet',
                message: 'Add from the catalog or create a custom exercise.',
                icon: Icons.playlist_add_rounded,
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: _exercises.length,
              onReorderItem: _onReorder,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return ExerciseEditorTile(
                  key: ValueKey(exercise.id),
                  exercise: exercise,
                  index: index,
                  onEdit: () => _editExercise(index),
                  onDelete: () => _removeExercise(index),
                );
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  Future<void> _showAddOptions() async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('From catalog'),
                subtitle: const Text('Browse common exercises'),
                onTap: () => Navigator.pop(context, _AddChoice.catalog),
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Custom exercise'),
                subtitle: const Text('Timer or sets from scratch'),
                onTap: () => Navigator.pop(context, _AddChoice.custom),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) {
      return;
    }

    if (choice == _AddChoice.catalog) {
      await _addFromCatalog();
    } else {
      await _addCustom();
    }
  }

  Future<void> _addFromCatalog() async {
    final catalogItem = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute(builder: (_) => const CatalogScreen()),
    );
    if (!mounted || catalogItem == null) {
      return;
    }

    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          initialName: catalogItem.name,
        ),
      ),
    );
    if (!mounted || exercise == null) {
      return;
    }

    setState(() => _exercises = [..._exercises, exercise]);
  }

  Future<void> _addCustom() async {
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const ExerciseEditorScreen()),
    );
    if (!mounted || exercise == null) {
      return;
    }
    setState(() => _exercises = [..._exercises, exercise]);
  }

  Future<void> _editExercise(int index) async {
    final updated = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(initial: _exercises[index]),
      ),
    );
    if (!mounted || updated == null) {
      return;
    }
    setState(() {
      _exercises = [
        for (var i = 0; i < _exercises.length; i++)
          if (i == index) updated else _exercises[i],
      ];
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises = [
        for (var i = 0; i < _exercises.length; i++)
          if (i != index) _exercises[i],
      ];
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a workout name')),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one exercise')),
      );
      return;
    }

    setState(() => _saving = true);
    final workout = Workout(
      id: _workoutId,
      name: name,
      exercises: List<Exercise>.unmodifiable(_exercises),
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
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
}

enum _AddChoice { catalog, custom }
