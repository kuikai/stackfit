part of 'account_provider.dart';

mixin AccountSync on StateNotifier<AccountState> {
  AccountStorage get _storage;
  AccountApiClient get _api;
  AccountSnapshot Function() get _readSnapshot;
  Future<void> Function(AccountSnapshot snapshot) get _writeSnapshot;
  set _applying(bool value);
  bool get _pushQueued;
  set _pushQueued(bool value);
  bool get _pushRunning;
  set _pushRunning(bool value);

  Future<void> _reconcile(String token, RemoteAccountData remote) async {
    _pushRunning = true;
    try {
      final local = _readSnapshot();
      final holdLocal =
          _storage.loadOrigin() == DataOrigin.device && local.hasProgress;
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
