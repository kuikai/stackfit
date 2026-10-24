import 'catalog_exercise.dart';
import 'exercise.dart';

/// The catalog list with [exercise] added under Custom.
///
/// Returns [custom] unchanged when the name is blank or already in the
/// built-in catalog. The same custom name is updated in place.
List<CatalogExercise> withCustomExercise(
  List<CatalogExercise> custom,
  Exercise exercise,
) {
  final trimmed = exercise.name.trim();
  if (trimmed.isEmpty || _builtInHasName(trimmed)) {
    return custom;
  }
  final key = trimmed.toLowerCase();
  final index = custom.indexWhere(
    (item) => item.name.trim().toLowerCase() == key,
  );
  final entry = _customEntry(
    id: index == -1 ? _customCatalogId(trimmed, custom) : custom[index].id,
    name: trimmed,
    exercise: exercise,
  );
  if (index == -1) {
    return [...custom, entry];
  }
  if (_sameCatalogEntry(custom[index], entry)) {
    return custom;
  }
  return [
    for (var i = 0; i < custom.length; i++)
      if (i == index) entry else custom[i],
  ];
}

CatalogExercise _customEntry({
  required String id,
  required String name,
  required Exercise exercise,
}) {
  return CatalogExercise(
    id: id,
    name: name,
    category: ExerciseCatalog.customCategory,
    type: exercise.type,
    workSeconds: exercise.workSeconds,
    restSeconds: exercise.restSeconds,
    sets: exercise.sets,
    reps: exercise.reps,
  );
}

bool _builtInHasName(String name) {
  final key = name.toLowerCase();
  return ExerciseCatalog.all.any(
    (item) => item.name.trim().toLowerCase() == key,
  );
}

bool _sameCatalogEntry(CatalogExercise left, CatalogExercise right) {
  return left.id == right.id &&
      left.name == right.name &&
      left.category == right.category &&
      left.type == right.type &&
      left.workSeconds == right.workSeconds &&
      left.restSeconds == right.restSeconds &&
      left.sets == right.sets &&
      left.reps == right.reps;
}

String _customCatalogId(String name, List<CatalogExercise> custom) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  final base = slug.isEmpty ? 'custom-exercise' : 'custom-$slug';
  final used = custom.map((item) => item.id).toSet();
  if (!used.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (used.contains('$base-$suffix')) {
    suffix += 1;
  }
  return '$base-$suffix';
}
