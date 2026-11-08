import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/account_snapshot.dart';

enum DataOrigin { device, account }

/// Who is signed in, plus sync bookkeeping that is not the workout list itself.
class AccountSession {
  const AccountSession({
    required this.userId,
    required this.email,
    required this.token,
    this.displayName,
  });

  final String userId;
  final String email;
  final String token;
  final String? displayName;

  AccountSession copyWith({
    String? displayName,
    bool clearDisplayName = false,
  }) {
    return AccountSession(
      userId: userId,
      email: email,
      token: token,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'token': token,
      'displayName': displayName,
    };
  }

  factory AccountSession.fromJson(Map<String, dynamic> json) {
    final name = json['displayName'] as String?;
    return AccountSession(
      userId: json['userId'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
      displayName: name == null || name.trim().isEmpty ? null : name.trim(),
    );
  }
}

class AccountStorage {
  AccountStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _sessionKey = 'stackfit_account_session';
  static const _originKey = 'stackfit_data_origin';
  static const _unmovedKey = 'stackfit_unmoved_device_snapshot';
  static const _deletionsKey = 'stackfit_deleted_workouts';
  static const _sessionDeletionsKey = 'stackfit_deleted_sessions';
  static const _appearanceUpdatedAtKey = 'stackfit_appearance_updated_at';
  static const _homeOrderUpdatedAtKey = 'stackfit_home_order_updated_at';

  AccountSession? loadSession() {
    final raw = _prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return AccountSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Saved sign-in was unreadable. Treat this device as signed out.
      return null;
    }
  }

  Future<void> saveSession(AccountSession session) async {
    await _prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  Future<void> clearSession() async {
    await _prefs.remove(_sessionKey);
  }

  DataOrigin loadOrigin() {
    return _prefs.getString(_originKey) == DataOrigin.account.name
        ? DataOrigin.account
        : DataOrigin.device;
  }

  Future<void> setOrigin(DataOrigin origin) async {
    await _prefs.setString(_originKey, origin.name);
  }

  DateTime loadAppearanceUpdatedAt() {
    final raw = _prefs.getString(_appearanceUpdatedAtKey);
    return DateTime.tryParse(raw ?? '') ?? DateTime.utc(1970);
  }

  Future<void> setAppearanceUpdatedAt(DateTime updatedAt) async {
    await _prefs.setString(
      _appearanceUpdatedAtKey,
      updatedAt.toUtc().toIso8601String(),
    );
  }

  DateTime loadHomeOrderUpdatedAt() {
    final raw = _prefs.getString(_homeOrderUpdatedAtKey);
    return DateTime.tryParse(raw ?? '') ?? DateTime.utc(1970);
  }

  Future<void> setHomeOrderUpdatedAt(DateTime updatedAt) async {
    await _prefs.setString(
      _homeOrderUpdatedAtKey,
      updatedAt.toUtc().toIso8601String(),
    );
  }

  List<SnapshotDeletion> loadDeletions() => _loadDeletions(_deletionsKey);

  List<SnapshotDeletion> loadSessionDeletions() =>
      _loadDeletions(_sessionDeletionsKey);

  Future<void> addDeletion(String id, DateTime deletedAt) {
    return _addDeletions(_deletionsKey, [id], deletedAt);
  }

  Future<void> addSessionDeletion(String id, DateTime deletedAt) {
    return _addDeletions(_sessionDeletionsKey, [id], deletedAt);
  }

  Future<void> addSessionDeletions(Iterable<String> ids, DateTime deletedAt) {
    return _addDeletions(_sessionDeletionsKey, ids, deletedAt);
  }

  Future<void> replaceDeletions(List<SnapshotDeletion> deletions) {
    return _replaceDeletions(_deletionsKey, deletions);
  }

  Future<void> replaceSessionDeletions(List<SnapshotDeletion> deletions) {
    return _replaceDeletions(_sessionDeletionsKey, deletions);
  }

  AccountSnapshot? loadUnmoved() {
    final raw = _prefs.getString(_unmovedKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return AccountSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Saved device copy was unreadable. Nothing is waiting to move.
      return null;
    }
  }

  bool get hasUnmoved => loadUnmoved() != null;

  Future<void> saveUnmoved(AccountSnapshot snapshot) async {
    await _prefs.setString(_unmovedKey, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearUnmoved() async {
    await _prefs.remove(_unmovedKey);
  }

  List<SnapshotDeletion> _loadDeletions(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (item) =>
                SnapshotDeletion.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      // Saved deletions were unreadable. Keep the records that are still here.
      return const [];
    }
  }

  Future<void> _addDeletions(
    String key,
    Iterable<String> ids,
    DateTime deletedAt,
  ) async {
    final deletions = [..._loadDeletions(key)];
    final when = deletedAt.toUtc();
    for (final id in ids) {
      _upsertDeletion(deletions, SnapshotDeletion(id: id, deletedAt: when));
    }
    await _replaceDeletions(key, deletions);
  }

  Future<void> _replaceDeletions(
    String key,
    List<SnapshotDeletion> deletions,
  ) async {
    if (deletions.isEmpty) {
      await _prefs.remove(key);
      return;
    }
    await _prefs.setString(
      key,
      jsonEncode(deletions.map((item) => item.toJson()).toList()),
    );
  }
}

void _upsertDeletion(
  List<SnapshotDeletion> deletions,
  SnapshotDeletion deletion,
) {
  final existingIndex = deletions.indexWhere((item) => item.id == deletion.id);
  if (existingIndex < 0) {
    deletions.add(deletion);
    return;
  }
  final existing = deletions[existingIndex];
  if (deletion.deletedAt.isAfter(existing.deletedAt)) {
    deletions[existingIndex] = deletion;
  }
}
