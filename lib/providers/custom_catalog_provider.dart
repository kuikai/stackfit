import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/catalog_exercise.dart';
import '../models/custom_catalog.dart';
import '../models/exercise.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

final customCatalogProvider =
    StateNotifierProvider<CustomCatalogNotifier, List<CatalogExercise>>((ref) {
      return CustomCatalogNotifier(ref.watch(storageServiceProvider));
    });

/// Exercises you added, saved on the phone and shown in the catalog.
class CustomCatalogNotifier extends StateNotifier<List<CatalogExercise>> {
  CustomCatalogNotifier(this._storage) : super(_storage.loadCustomExercises());

  final StorageService _storage;

  /// Adds [exercise] under Custom when that name is not built in.
  Future<void> remember(Exercise exercise) async {
    final next = withCustomExercise(state, exercise);
    if (identical(next, state)) {
      return;
    }
    state = next;
    await _storage.saveCustomExercises(state);
  }

  /// Replaces the list from an account sync.
  Future<void> replaceAll(List<CatalogExercise> exercises) async {
    state = [...exercises];
    await _storage.saveCustomExercises(state);
  }
}
