import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/utils.dart';
import '../../models/models.dart';

/// Create or edit a single exercise (timer or sets).
class ExerciseEditorScreen extends StatefulWidget {
  const ExerciseEditorScreen({
    super.key,
    this.initial,
    this.initialName,
  });

  final Exercise? initial;
  final String? initialName;

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _workController;
  late final TextEditingController _restController;
  late final TextEditingController _setsController;
  late final TextEditingController _repsController;
  late ExerciseType _type;
  late final String _id;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _id = initial?.id ?? AppUtils.newId();
    _type = initial?.type ?? ExerciseType.sets;
    _nameController = TextEditingController(
      text: initial?.name ?? widget.initialName ?? '',
    );
    _workController = TextEditingController(
      text: '${initial?.workSeconds ?? 45}',
    );
    _restController = TextEditingController(
      text: '${initial?.restSeconds ?? (_type == ExerciseType.timer ? 15 : 60)}',
    );
    _setsController = TextEditingController(
      text: '${initial?.sets ?? 3}',
    );
    _repsController = TextEditingController(
      text: initial?.reps?.toString() ?? '8',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _workController.dispose();
    _restController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final actionLabel = isEditing ? 'Save' : 'Add exercise';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit exercise' : 'Add exercise'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Plank',
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Type',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ExerciseType>(
            segments: const [
              ButtonSegment(
                value: ExerciseType.timer,
                label: Text('Timer'),
                icon: Icon(Icons.timer_outlined),
              ),
              ButtonSegment(
                value: ExerciseType.sets,
                label: Text('Sets'),
                icon: Icon(Icons.replay_outlined),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selected) {
              setState(() => _type = selected.first);
            },
          ),
          const SizedBox(height: 24),
          if (_type == ExerciseType.timer) ...[
            _numberField(
              controller: _workController,
              label: 'Work (seconds)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _restController,
              label: 'Rest (seconds)',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _setsController,
              label: 'Sets / rounds',
            ),
          ] else ...[
            _numberField(
              controller: _setsController,
              label: 'Sets',
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _repsController,
              label: 'Reps (optional)',
              required: false,
            ),
            const SizedBox(height: 12),
            _numberField(
              controller: _restController,
              label: 'Rest between sets (seconds)',
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _save,
              child: Text(actionLabel),
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool required = true,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        helperText: required ? null : 'Leave empty if not needed',
      ),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Enter an exercise name');
      return;
    }

    if (_type == ExerciseType.timer) {
      final work = int.tryParse(_workController.text.trim());
      final rest = int.tryParse(_restController.text.trim());
      final sets = int.tryParse(_setsController.text.trim());
      if (work == null || work <= 0) {
        _showError('Work time must be at least 1 second');
        return;
      }
      if (rest == null || rest < 0) {
        _showError('Enter a valid rest time');
        return;
      }
      if (sets == null || sets <= 0) {
        _showError('Sets must be at least 1');
        return;
      }
      Navigator.of(context).pop(
        Exercise.timer(
          id: _id,
          name: name,
          workSeconds: work,
          restSeconds: rest,
          sets: sets,
        ),
      );
      return;
    }

    final sets = int.tryParse(_setsController.text.trim());
    final rest = int.tryParse(_restController.text.trim());
    final repsRaw = _repsController.text.trim();
    final reps = repsRaw.isEmpty ? null : int.tryParse(repsRaw);

    if (sets == null || sets <= 0) {
      _showError('Sets must be at least 1');
      return;
    }
    if (rest == null || rest < 0) {
      _showError('Enter a valid rest time');
      return;
    }
    if (repsRaw.isNotEmpty && (reps == null || reps <= 0)) {
      _showError('Reps must be a positive number');
      return;
    }

    Navigator.of(context).pop(
      Exercise.sets(
        id: _id,
        name: name,
        sets: sets,
        reps: reps,
        restSeconds: rest,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
