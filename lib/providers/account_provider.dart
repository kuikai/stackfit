import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/skins.dart';
import '../core/theme_mode_codec.dart';
import '../models/account_snapshot.dart';
import '../models/app_settings.dart';
import '../models/catalog_exercise.dart';
import '../models/completed_session.dart';
import '../models/workout.dart';
import '../services/account/account_api_client.dart';
import '../services/account/account_storage.dart';
import '../services/account/snapshot_merge.dart';
import 'account_state.dart';
import 'app_providers.dart';
import 'completed_sessions_provider.dart';
import 'custom_catalog_provider.dart';
import 'settings_provider.dart';
import 'workouts_provider.dart';

export 'account_state.dart';

part 'account_sync.dart';

final accountProvider = StateNotifierProvider<AccountNotifier, AccountState>((
  ref,
) {
  final storage = ref.watch(accountStorageProvider);
  final notifier = AccountNotifier(
    storage: storage,
    api: ref.watch(accountApiProvider),
    readSnapshot: () => _readSnapshot(ref, storage),
    writeSnapshot: (snapshot) => _writeSnapshot(ref, snapshot),
  );

  ref.listen<List<Workout>>(workoutsProvider, (previous, next) {
    notifier.onLocalDataChanged();
  });
  ref.listen<List<CompletedSession>>(completedSessionsProvider, (
    previous,
    next,
  ) {
    notifier.onLocalDataChanged();
  });
  ref.listen<AppSettings>(settingsProvider, (previous, next) {
    notifier.onLocalDataChanged();
  });
  ref.listen<List<CatalogExercise>>(customCatalogProvider, (previous, next) {
    notifier.onLocalDataChanged();
  });
  return notifier;
});

AccountSnapshot _readSnapshot(Ref ref, AccountStorage storage) {
  final settings = ref.read(settingsProvider);
  return AccountSnapshot(
    workouts: ref.read(workoutsProvider),
    deletedWorkouts: storage.loadDeletions(),
    sessions: ref.read(completedSessionsProvider),
    customExercises: ref.read(customCatalogProvider),
    themeMode: themeModeToStorage(settings.themeMode),
    skin: settings.skin.name,
    appearanceUpdatedAt: storage.loadAppearanceUpdatedAt(),
  );
}

Future<void> _writeSnapshot(Ref ref, AccountSnapshot snapshot) async {
  final storage = ref.read(accountStorageProvider);
  await storage.replaceDeletions(snapshot.deletedWorkouts);
  await storage.setAppearanceUpdatedAt(snapshot.appearanceUpdatedAt);
  await ref.read(workoutsProvider.notifier).replaceAll(snapshot.workouts);
  await ref
      .read(completedSessionsProvider.notifier)
      .replaceAll(snapshot.sessions);
  await ref
      .read(customCatalogProvider.notifier)
      .replaceAll(snapshot.customExercises);
  await ref
      .read(settingsProvider.notifier)
      .applyFromAccount(
        themeMode: themeModeFromStorage(snapshot.themeMode),
        skin: AppSkin.fromStorage(snapshot.skin),
      );
}

class AccountNotifier extends StateNotifier<AccountState> with AccountSync {
  AccountNotifier({
    required this._storage,
    required this._api,
    required this._readSnapshot,
    required this._writeSnapshot,
  }) : super(const AccountState()) {
    final session = _storage.loadSession();
    if (session == null) {
      return;
    }
    state = AccountState(
      session: session,
      saveStatus: SaveStatus.saving,
      hasUnmovedDeviceData: _storage.hasUnmoved,
    );
    Future.microtask(syncIfSignedIn);
  }

  @override
  final AccountStorage _storage;
  @override
  final AccountApiClient _api;
  @override
  final AccountSnapshot Function() _readSnapshot;
  @override
  final Future<void> Function(AccountSnapshot snapshot) _writeSnapshot;

  @override
  bool _applying = false;
  @override
  bool _pushQueued = false;
  @override
  bool _pushRunning = false;

  void onLocalDataChanged() {
    if (_applying) {
      return;
    }
    if (state.session == null) {
      unawaited(_storage.setOrigin(DataOrigin.device));
      return;
    }
    _pushQueued = true;
    unawaited(_drainPushes());
  }

  void syncIfSignedIn() {
    if (state.session == null) {
      return;
    }
    onLocalDataChanged();
  }

  void clearMovePrompt() {
    if (!state.promptMove) {
      return;
    }
    state = state.copyWith(promptMove: false);
  }

  Future<String?> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _openSession(
      () => _api.signUp(
        email: email.trim(),
        password: password,
        displayName: displayName?.trim(),
      ),
    );
  }

  Future<String?> signIn({required String email, required String password}) {
    return _openSession(
      () => _api.signIn(email: email.trim(), password: password),
    );
  }

  Future<void> signOut() async {
    final token = state.session?.token;
    state = const AccountState();
    await _storage.clearSession();
    if (token == null) {
      return;
    }
    try {
      await _api.signOut(token);
    } catch (_) {
      // Local sign-out already finished. The server token can expire unused.
    }
  }

  /// Deletes the account on the server. Workouts already on this phone stay.
  Future<String?> deleteAccount(String password) async {
    final token = state.session?.token;
    if (token == null) {
      return 'Sign in first.';
    }
    try {
      await _api.deleteAccount(token: token, password: password);
    } on AccountApiException catch (error) {
      return error.message;
    }
    state = const AccountState();
    await _storage.clearSession();
    return null;
  }

  /// Asks the server to print a reset code. Null means the request was accepted.
  Future<String?> requestPasswordReset(String email) async {
    try {
      await _api.requestPasswordReset(email.trim());
      return null;
    } on AccountApiException catch (error) {
      return error.message;
    }
  }

  /// Saves a new password, then signs in with it.
  Future<String?> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      await _api.resetPassword(
        email: email.trim(),
        code: code,
        password: password,
      );
    } on AccountApiException catch (error) {
      return error.message;
    }
    return signIn(email: email.trim(), password: password);
  }

  Future<String?> updateDisplayName(String name) async {
    final session = state.session;
    if (session == null) {
      return 'Sign in first.';
    }
    try {
      final saved = await _api.updateDisplayName(
        token: session.token,
        displayName: name.trim(),
      );
      final next = saved == null
          ? session.copyWith(clearDisplayName: true)
          : session.copyWith(displayName: saved);
      await _storage.saveSession(next);
      state = state.copyWith(session: next, clearError: true);
      return null;
    } on AccountApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> moveDeviceData() async {
    final session = state.session;
    final stash = _storage.loadUnmoved();
    if (session == null || stash == null) {
      return null;
    }

    state = state.copyWith(
      saveStatus: SaveStatus.saving,
      clearError: true,
      promptMove: false,
    );
    try {
      final remote = await _api.fetchData(session.token);
      final merged = mergeSnapshots(
        mergeSnapshots(_readSnapshot(), stash),
        remote.snapshot,
      );
      await _applySnapshot(merged);
      await _upload(session.token, merged, remote);
      await _storage.clearUnmoved();
      await _storage.setOrigin(DataOrigin.account);
      if (state.session?.token == session.token) {
        state = state.copyWith(
          saveStatus: SaveStatus.saved,
          hasUnmovedDeviceData: false,
          promptMove: false,
          clearError: true,
        );
      }
      return null;
    } on AccountApiException catch (error) {
      return _syncFailure(session.token, error, keepUnmoved: true);
    }
  }

  Future<String?> _openSession(
    Future<AccountSession> Function() authenticate,
  ) async {
    if (state.busy) {
      return null;
    }
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await authenticate();
      final remote = await _api.fetchData(session.token);
      await _storage.saveSession(session);
      state = AccountState(
        session: session,
        saveStatus: SaveStatus.saving,
        hasUnmovedDeviceData: _storage.hasUnmoved,
      );
      await _reconcile(session.token, remote);
      return null;
    } on AccountApiException catch (error) {
      await _storage.clearSession();
      state = AccountState(errorMessage: error.message);
      return error.message;
    }
  }
}
