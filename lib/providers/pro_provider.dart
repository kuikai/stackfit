import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';
import 'app_providers.dart';

final isProProvider = StateNotifierProvider<IsProNotifier, bool>((ref) {
  return IsProNotifier(ref.watch(storageServiceProvider));
});

class IsProNotifier extends StateNotifier<bool> {
  IsProNotifier(this._storage) : super(_storage.loadIsPro());

  final StorageService _storage;

  Future<void> setIsPro(bool isPro) async {
    state = isPro;
    await _storage.saveIsPro(isPro);
  }

  /// Dev / test helper until RevenueCat is wired.
  Future<void> unlockProForTesting() => setIsPro(true);

  Future<void> resetProForTesting() => setIsPro(false);
}
