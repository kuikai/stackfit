import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants.dart';
import '../services/account/account_api_client.dart';
import '../services/account/account_storage.dart';
import '../services/storage_service.dart';

/// Must be overridden in [main] with a real [SharedPreferences] instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final accountStorageProvider = Provider<AccountStorage>((ref) {
  return AccountStorage(ref.watch(sharedPreferencesProvider));
});

final accountApiProvider = Provider<AccountApiClient>((ref) {
  final client = AccountApiClient(baseUrl: AppConstants.accountServerUrl);
  ref.onDispose(client.close);
  return client;
});
