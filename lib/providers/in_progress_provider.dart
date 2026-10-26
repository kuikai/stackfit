import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';

final inProgressProvider =
    StateNotifierProvider<InProgressNotifier, List<InProgressWorkout>>((ref) {
      return InProgressNotifier(ref.watch(storageServiceProvider));
    });

/// Unfinished workouts saved on the phone. Not part of account sync.
class InProgressNotifier extends StateNotifier<List<InProgressWorkout>> {
  InProgressNotifier(this._storage) : super(_storage.loadInProgress());

  final StorageService _storage;
  Future<void> _writes = Future<void>.value();

  InProgressWorkout? forWorkout(String workoutId) {
    for (final run in state) {
      if (run.workout.id == workoutId) {
        return run;
      }
    }
    return null;
  }

  InProgressWorkout? forOrigin(String origin) {
    for (final run in state) {
      if (run.origin == origin) {
        return run;
      }
    }
    return null;
  }

  Future<void> save(InProgressWorkout run) {
    return _commit([
      for (final existing in state)
        if (!_sameSlot(existing, run)) existing,
      run,
    ]);
  }

  Future<void> discard(String workoutId) {
    final next = [
      for (final run in state)
        if (run.workout.id != workoutId) run,
    ];
    if (next.length == state.length) {
      return Future<void>.value();
    }
    return _commit(next);
  }

  Future<void> _commit(List<InProgressWorkout> runs) {
    state = runs;
    final pending = _writes.then((_) => _storage.saveInProgress(runs));
    // A failed write must not block the next one. The next change writes again.
    _writes = pending.then((_) {}, onError: (Object _, StackTrace _) {});
    return pending;
  }

  bool _sameSlot(InProgressWorkout existing, InProgressWorkout run) {
    if (existing.workout.id == run.workout.id) {
      return true;
    }
    final origin = run.origin;
    return origin != null && origin.isNotEmpty && existing.origin == origin;
  }
}
