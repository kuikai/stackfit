import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';
import 'pro_provider.dart';

final workoutsProvider =
    StateNotifierProvider<WorkoutsNotifier, List<Workout>>((ref) {
  return WorkoutsNotifier(ref.watch(storageServiceProvider));
});

/// Whether the user can create another workout (Pro or under free limit).
final canCreateWorkoutProvider = Provider<bool>((ref) {
  final isPro = ref.watch(isProProvider);
  if (isPro) {
    return true;
  }
  final count = ref.watch(workoutsProvider).length;
  return count < AppConstants.freeWorkoutLimit;
});

class WorkoutsNotifier extends StateNotifier<List<Workout>> {
  WorkoutsNotifier(this._storage) : super(_storage.loadWorkouts());

  final StorageService _storage;

  Future<void> _persist() async {
    await _storage.saveWorkouts(state);
  }

  Future<bool> addWorkout(Workout workout) async {
    state = [...state, workout];
    await _persist();
    return true;
  }

  Future<void> updateWorkout(Workout workout) async {
    state = [
      for (final existing in state)
        if (existing.id == workout.id) workout else existing,
    ];
    await _persist();
  }

  Future<void> deleteWorkout(String id) async {
    state = state.where((workout) => workout.id != id).toList();
    await _persist();
  }

  Future<Workout?> duplicateWorkout(String id) async {
    final source = state.where((workout) => workout.id == id).firstOrNull;
    if (source == null) {
      return null;
    }

    final now = DateTime.now();
    final copy = source.copyWith(
      id: AppUtils.newId(),
      name: '${source.name} (copy)',
      createdAt: now,
      updatedAt: now,
      exercises: source.exercises
          .map((exercise) => exercise.copyWith(id: AppUtils.newId()))
          .toList(),
    );
    await addWorkout(copy);
    return copy;
  }

  Workout? byId(String id) {
    for (final workout in state) {
      if (workout.id == id) {
        return workout;
      }
    }
    return null;
  }
}
