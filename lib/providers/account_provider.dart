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
import 'app_providers.dart';
import 'completed_sessions_provider.dart';
import 'custom_catalog_provider.dart';
import 'settings_provider.dart';
import 'workouts_provider.dart';

enum SaveStatus { localOnly, saved, saving, offline, error }

class AccountState {
  const AccountState({
    this.session,
    this.saveStatus = SaveStatus.localOnly,
    this.errorMessage,
    this.hasUnmovedDeviceData = false,
    this.promptMove = false,
    this.busy = false,
  });

  final AccountSession? session;
  final SaveStatus saveStatus;
  final String? errorMessage;
  final bool hasUnmovedDeviceData;
  final bool promptMove;
  final bool busy;

  bool get isSignedIn => session != null;

  AccountState copyWith({
    AccountSession? session,
    bool clearSession = false,
    SaveStatus? saveStatus,
    String? errorMessage,
    bool clearError = false,
    bool? hasUnmovedDeviceData,
    bool? promptMove,
    bool? busy,
  }) {
    return AccountState(
      session: clearSession ? null : (session ?? this.session),
      saveStatus: saveStatus ?? this.saveStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasUnmovedDeviceData:
          hasUnmovedDeviceData ?? this.hasUnmovedDeviceData,
      promptMove: promptMove ?? this.promptMove,
      busy: busy ?? this.busy,
    );
  }
}

final accountProvider =
    StateNotifierProvider<AccountNotifier, AccountState>((ref) {
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

class AccountNotifier extends StateNotifier<AccountState> {
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

  final AccountStorage _storage;
  final AccountApiClient _api;
  final AccountSnapshot Function() _readSnapshot;
  final Future<void> Function(AccountSnapshot snapshot) _writeSnapshot;

  bool _applying = false;
  bool _pushQueued = false;
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

  Future<String?> signIn({
    required String email,
    required String password,
  }) {
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

  Future<void> _reconcile(String token, RemoteAccountData remote) async {
    _pushRunning = true;
    try {
      final local = _readSnapshot();
      final holdLocal = _storage.loadOrigin() == DataOrigin.device &&
          local.hasProgress;
      if (holdLocal) {
        await _holdDeviceData(token, local, remote);
        return;
      }
      final merged = mergeSnapshots(local, remote.snapshot);
      if (merged.canonicalJson != local.canonicalJson) {
        await _applySnapshot(merged);
      }
      await _upload(token, merged, remote);
      await _storage.setOrigin(DataOrigin.account);
      if (state.session?.token == token) {
        state = state.copyWith(
          saveStatus: SaveStatus.saved,
          clearError: true,
          hasUnmovedDeviceData: _storage.hasUnmoved,
        );
      }
    } on AccountApiException catch (error) {
      _syncFailure(token, error, keepUnmoved: _storage.hasUnmoved);
    } finally {
      _pushRunning = false;
      if (_pushQueued) {
        unawaited(_drainPushes());
      }
    }
  }

  Future<void> _holdDeviceData(
    String token,
    AccountSnapshot local,
    RemoteAccountData remote,
  ) async {
    final existing = _storage.loadUnmoved();
    final pending = existing == null ? local : mergeSnapshots(existing, local);
    await _storage.saveUnmoved(pending);

    final appearance = mergeSnapshots(local, remote.snapshot);
    final working = remote.snapshot.copyWith(
      themeMode: appearance.themeMode,
      skin: appearance.skin,
      appearanceUpdatedAt: appearance.appearanceUpdatedAt,
    );
    await _applySnapshot(working);
    await _storage.setOrigin(DataOrigin.account);
    if (state.session?.token == token) {
      state = state.copyWith(
        saveStatus: SaveStatus.saving,
        hasUnmovedDeviceData: true,
        promptMove: true,
      );
    }
    await _upload(token, working, remote);
    if (state.session?.token != token) {
      return;
    }
    state = state.copyWith(
      saveStatus: SaveStatus.saved,
      clearError: true,
      hasUnmovedDeviceData: true,
      promptMove: true,
    );
  }

  Future<void> _drainPushes() async {
    if (_pushRunning) {
      return;
    }
    _pushRunning = true;
    try {
      while (_pushQueued) {
        _pushQueued = false;
        await _pushWorkingCopy();
      }
    } finally {
      _pushRunning = false;
    }
  }

  Future<void> _pushWorkingCopy() async {
    final token = state.session?.token;
    if (token == null) {
      return;
    }
    state = state.copyWith(saveStatus: SaveStatus.saving, clearError: true);
    try {
      final remote = await _api.fetchData(token);
      final merged = mergeSnapshots(_readSnapshot(), remote.snapshot);
      if (merged.canonicalJson != _readSnapshot().canonicalJson) {
        await _applySnapshot(merged);
      }
      await _upload(token, merged, remote);
      if (state.session?.token == token) {
        state = state.copyWith(saveStatus: SaveStatus.saved, clearError: true);
      }
    } on AccountApiException catch (error) {
      _syncFailure(token, error, keepUnmoved: _storage.hasUnmoved);
    }
  }

  Future<void> _upload(
    String token,
    AccountSnapshot merged,
    RemoteAccountData remote,
  ) async {
    var current = remote;
    var toSave = merged;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (toSave.canonicalJson == current.snapshot.canonicalJson) {
        _rememberDisplayName(token, current.displayName);
        return;
      }
      try {
        final saved = await _api.putData(
          token: token,
          baseRevision: current.revision,
          snapshot: toSave,
        );
        _rememberDisplayName(token, saved.displayName);
        return;
      } on AccountApiException catch (error) {
        final conflict = error.conflict;
        if (conflict == null || attempt == 2) {
          rethrow;
        }
        toSave = mergeSnapshots(toSave, conflict.snapshot);
        await _applySnapshot(toSave);
        current = conflict;
      }
    }
  }

  Future<void> _applySnapshot(AccountSnapshot snapshot) async {
    _applying = true;
    try {
      await _writeSnapshot(snapshot);
    } finally {
      _applying = false;
    }
  }

  void _rememberDisplayName(String token, String? displayName) {
    final session = state.session;
    if (session == null || session.token != token) {
      return;
    }
    if (session.displayName == displayName) {
      return;
    }
    final next = displayName == null
        ? session.copyWith(clearDisplayName: true)
        : session.copyWith(displayName: displayName);
    state = state.copyWith(session: next);
    unawaited(_storage.saveSession(next));
  }

  String? _syncFailure(
    String token,
    AccountApiException error, {
    required bool keepUnmoved,
  }) {
    if (state.session?.token != token) {
      return error.message;
    }
    if (error.statusCode == 401) {
      state = const AccountState(errorMessage: 'Sign in again.');
      unawaited(_storage.clearSession());
      return error.message;
    }
    state = state.copyWith(
      saveStatus: error.offline ? SaveStatus.offline : SaveStatus.error,
      errorMessage: error.message,
      hasUnmovedDeviceData: keepUnmoved,
    );
    return error.message;
  }
}
