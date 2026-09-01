import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import 'app_providers.dart';
import 'pro_provider.dart';

final completedSessionsProvider =
    StateNotifierProvider<CompletedSessionsNotifier, List<CompletedSession>>(
  (ref) {
    return CompletedSessionsNotifier(ref.watch(storageServiceProvider));
  },
);

/// History list respecting the free-tier cap when the user is not Pro.
final visibleCompletedSessionsProvider = Provider<List<CompletedSession>>((ref) {
  final sessions = ref.watch(completedSessionsProvider);
  final isPro = ref.watch(isProProvider);
  if (isPro || sessions.length <= AppConstants.freeHistoryLimit) {
    return sessions;
  }
  return sessions.take(AppConstants.freeHistoryLimit).toList();
});

class CompletedSessionsNotifier
    extends StateNotifier<List<CompletedSession>> {
  CompletedSessionsNotifier(this._storage)
      : super(_sorted(_storage.loadCompletedSessions()));

  final StorageService _storage;

  static List<CompletedSession> _sorted(List<CompletedSession> sessions) {
    final copy = [...sessions];
    copy.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return copy;
  }

  Future<void> _persist() async {
    await _storage.saveCompletedSessions(state);
  }

  Future<void> addSession(CompletedSession session) async {
    state = _sorted([session, ...state]);
    await _persist();
  }

  Future<void> clearAll() async {
    state = const [];
    await _persist();
  }
}
