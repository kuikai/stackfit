import 'package:flutter/material.dart';

import '../../core/utils.dart';
import '../../models/models.dart';
import '../catalog/catalog_screen.dart';
import '../exercise_editor/exercise_editor_screen.dart';

enum WorkoutAddChoice { catalog, custom, circuit }

/// What to add at the bottom of the workout editor.
Future<WorkoutAddChoice?> askWhatToAdd(BuildContext context) {
  return showModalBottomSheet<WorkoutAddChoice>(
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
              onTap: () => Navigator.pop(context, WorkoutAddChoice.catalog),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Custom exercise'),
              subtitle: const Text('Timer or sets from scratch'),
              onTap: () => Navigator.pop(context, WorkoutAddChoice.custom),
            ),
            ListTile(
              leading: const Icon(Icons.loop_rounded),
              title: const Text('Circuit'),
              subtitle: const Text('A group of exercises that repeats'),
              onTap: () => Navigator.pop(context, WorkoutAddChoice.circuit),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// True when the station should come from the catalog.
Future<bool?> askStationSource(BuildContext context) {
  return showModalBottomSheet<bool>(
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
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Custom exercise'),
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<Exercise?> pickExercise(
  BuildContext context, {
  required bool fromCatalog,
  Exercise? initial,
  bool inCircuit = false,
}) async {
  var name = initial?.name;
  if (fromCatalog) {
    final catalogItem = await Navigator.of(context).push<CatalogExercise>(
      MaterialPageRoute(builder: (_) => const CatalogScreen()),
    );
    if (!context.mounted || catalogItem == null) {
      return null;
    }
    name = catalogItem.name;
  }
  if (!context.mounted) {
    return null;
  }
  return Navigator.of(context).push<Exercise>(
    MaterialPageRoute(
      builder: (_) => ExerciseEditorScreen(
        initial: initial,
        initialName: initial == null ? name : null,
        inCircuit: inCircuit,
      ),
    ),
  );
}

Circuit newCircuit() {
  return Circuit(
    id: AppUtils.newId(),
    rounds: 3,
    restBetweenRoundsSeconds: 60,
    exercises: const [],
  );
}

Circuit? circuitById(List<WorkoutBlock> blocks, String circuitId) {
  for (final block in blocks) {
    if (block is CircuitBlock && block.circuit.id == circuitId) {
      return block.circuit;
    }
  }
  return null;
}

List<WorkoutBlock> mapCircuit(
  List<WorkoutBlock> blocks,
  String circuitId,
  Circuit Function(Circuit circuit) update,
) {
  return [
    for (final block in blocks)
      if (block is CircuitBlock && block.circuit.id == circuitId)
        CircuitBlock(update(block.circuit))
      else
        block,
  ];
}
