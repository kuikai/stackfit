import 'package:flutter/material.dart';

import '../../models/models.dart';

Future<String?> promptSectionName(
  BuildContext context, {
  String? initial,
}) async {
  final controller = TextEditingController(text: initial ?? '');
  final result = await showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(initial == null ? 'New section' : 'Rename section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'e.g. Bro Split',
          ),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
  controller.dispose();
  return Workout.normalizeSection(result);
}

class MoveToSectionDialog extends StatefulWidget {
  const MoveToSectionDialog({
    super.key,
    required this.current,
    required this.sections,
  });

  final String? current;
  final List<String> sections;

  static const cancelled = '__cancelled__';
  static const none = '__none__';
  static const createNew = '__new__';

  @override
  State<MoveToSectionDialog> createState() => _MoveToSectionDialogState();
}

class _MoveToSectionDialogState extends State<MoveToSectionDialog> {
  late String _selected;
  final _newName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.current ?? MoveToSectionDialog.none;
  }

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Move to section'),
      content: SingleChildScrollView(
        child: RadioGroup<String>(
          groupValue: _selected,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selected = value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RadioListTile<String>(
                title: Text('No section'),
                value: MoveToSectionDialog.none,
              ),
              for (final section in widget.sections)
                RadioListTile<String>(
                  title: Text(section),
                  value: section,
                ),
              const RadioListTile<String>(
                title: Text('New section'),
                value: MoveToSectionDialog.createNew,
              ),
              if (_selected == MoveToSectionDialog.createNew)
                TextField(
                  controller: _newName,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Section name',
                    hintText: 'e.g. Bro Split',
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(MoveToSectionDialog.cancelled),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text('Move'),
        ),
      ],
    );
  }

  void _confirm() {
    if (_selected == MoveToSectionDialog.createNew) {
      final name = Workout.normalizeSection(_newName.text);
      Navigator.of(context).pop(name ?? MoveToSectionDialog.cancelled);
      return;
    }
    Navigator.of(context).pop(_selected);
  }
}

class PickWorkoutsDialog extends StatefulWidget {
  const PickWorkoutsDialog({
    super.key,
    required this.title,
    required this.workouts,
  });

  final String title;
  final List<Workout> workouts;

  @override
  State<PickWorkoutsDialog> createState() => _PickWorkoutsDialogState();
}

class _PickWorkoutsDialogState extends State<PickWorkoutsDialog> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final workout in widget.workouts)
              CheckboxListTile(
                title: Text(workout.name),
                value: _selected.contains(workout.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(workout.id);
                    } else {
                      _selected.remove(workout.id);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Skip'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              widget.workouts
                  .where((workout) => _selected.contains(workout.id))
                  .toList(),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
