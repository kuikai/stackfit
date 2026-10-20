import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../models/models.dart';
import '../services/account/account_storage.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';
import 'pro_provider.dart';

final workoutsProvider =
    StateNotifierProvider<WorkoutsNotifier, List<Workout>>((ref) {
  return WorkoutsNotifier(
    ref.watch(storageServiceProvider),
    ref.watch(accountStorageProvider),
  );
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
  WorkoutsNotifier(this._storage, this._accountStorage)
      : super(_storage.loadWorkouts());

  final StorageService _storage;
  final AccountStorage _accountStorage;

  Future<void> _persist() async {
    await _storage.saveWorkouts(state);
  }

  Future<bool> addWorkout(Workout workout) async {
    state = [...state, workout];
    await _persist();
    return true;
  }

  /// Adds several workouts (for example every day of a plan) with one save.
  Future<void> addWorkouts(List<Workout> workouts) async {
    if (workouts.isEmpty) {
      return;
    }
    state = [...state, ...workouts];
    await _persist();
  }

  Future<void> updateWorkout(Workout workout) async {
    state = [
      for (final existing in state)
        if (existing.id == workout.id) workout else existing,
    ];
    await _persist();
  }

  Future<void> deleteWorkout(String id) async {
    await _accountStorage.addDeletion(id, DateTime.now().toUtc());
    state = state.where((workout) => workout.id != id).toList();
    await _storage.saveWorkouts(state);
  }

  /// Replaces the list from an account sync without recording a new deletion.
  Future<void> replaceAll(List<Workout> workouts) async {
    state = [...workouts];
    await _storage.saveWorkouts(state);
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

  /// Distinct section names, in the order they first appear.
  List<String> get sectionNames {
    final names = <String>[];
    final seen = <String>{};
    for (final workout in state) {
      final section = workout.section;
      if (section == null || !seen.add(section)) {
        continue;
      }
      names.add(section);
    }
    return names;
  }

  Future<void> moveToSection(String workoutId, String? section) async {
    final workout = byId(workoutId);
    if (workout == null) {
      return;
    }
    final next = Workout.normalizeSection(section);
    if (workout.section == next) {
      return;
    }
    await updateWorkout(
      workout.copyWith(
        section: next,
        clearSection: next == null,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> renameSection(String from, String to) async {
    final next = Workout.normalizeSection(to);
    if (next == null || next == from) {
      return;
    }
    final now = DateTime.now();
    var changed = false;
    final updated = <Workout>[];
    for (final workout in state) {
      if (workout.section == from) {
        changed = true;
        updated.add(workout.copyWith(section: next, updatedAt: now));
      } else {
        updated.add(workout);
      }
    }
    if (!changed) {
      return;
    }
    state = updated;
    await _persist();
  }

  /// Removes the folder; the workouts stay, ungrouped.
  Future<void> dissolveSection(String section) async {
    final now = DateTime.now();
    var changed = false;
    final updated = <Workout>[];
    for (final workout in state) {
      if (workout.section == section) {
        changed = true;
        updated.add(workout.copyWith(clearSection: true, updatedAt: now));
      } else {
        updated.add(workout);
      }
    }
    if (!changed) {
      return;
    }
    state = updated;
    await _persist();
  }
}
