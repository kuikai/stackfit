part of 'account_store.dart';

extension AccountStoreFile on AccountStore {
  void _readUsers(Object? raw) {
    if (raw is! List<dynamic>) {
      return;
    }
    for (final item in raw.whereType<Map<Object?, Object?>>()) {
      final user = _UserRecord.fromJson(Map<String, dynamic>.from(item));
      _usersById[user.id] = user;
      _userIdByEmail[user.email] = user.id;
    }
  }

  void _readTokens(Object? raw) {
    if (raw is! List<dynamic>) {
      return;
    }
    for (final item in raw.whereType<Map<Object?, Object?>>()) {
      final json = Map<String, dynamic>.from(item);
      final hash = json['tokenHash'] as String?;
      final userId = json['userId'] as String?;
      if (hash != null && userId != null) {
        _userIdByTokenHash[hash] = userId;
      }
    }
  }

  void _readResets(Object? raw) {
    if (raw is! List<dynamic>) {
      return;
    }
    for (final item in raw.whereType<Map<Object?, Object?>>()) {
      final json = Map<String, dynamic>.from(item);
      final userId = json['userId'] as String?;
      final codeHash = json['codeHash'] as String?;
      final expires = DateTime.tryParse(json['expiresAt'] as String? ?? '');
      if (userId != null && codeHash != null && expires != null) {
        _resetsByUserId[userId] = _ResetRecord(
          codeHash: codeHash,
          expiresAt: expires,
        );
      }
    }
  }

  void _readData(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return;
    }
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map<Object?, Object?>) {
        continue;
      }
      final json = Map<String, dynamic>.from(value);
      final snapshot = json['snapshot'];
      _dataByUserId[key] = _DataRecord(
        revision: json['revision'] as int? ?? 0,
        snapshot: snapshot is Map<Object?, Object?>
            ? Map<String, dynamic>.from(snapshot)
            : emptySnapshot(),
      );
    }
  }
}

class AccountStoreException implements Exception {
  const AccountStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _UserRecord {
  const _UserRecord({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.displayName,
    required this.createdAt,
  });

  final String id;
  final String email;
  final String passwordHash;
  final String? displayName;
  final DateTime createdAt;

  _UserRecord copyWith({
    String? passwordHash,
    String? displayName,
    bool clearDisplayName = false,
  }) {
    return _UserRecord(
      id: id,
      email: email,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      createdAt: createdAt,
    );
  }

  StoredUser view() {
    return StoredUser(id: id, email: email, displayName: displayName);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'passwordHash': passwordHash,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory _UserRecord.fromJson(Map<String, dynamic> json) {
    return _UserRecord(
      id: json['id'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      displayName: cleanDisplayName(json['displayName'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class _ResetRecord {
  const _ResetRecord({required this.codeHash, required this.expiresAt});

  final String codeHash;
  final DateTime expiresAt;
}

class _DataRecord {
  const _DataRecord({required this.revision, required this.snapshot});

  final int revision;
  final Map<String, dynamic> snapshot;
}

String normalizeEmail(String email) => email.trim().toLowerCase();

String? cleanDisplayName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

Map<String, dynamic> emptySnapshot() {
  return {
    'workouts': <dynamic>[],
    'deletedWorkouts': <dynamic>[],
    'sessions': <dynamic>[],
    'customExercises': <dynamic>[],
    'themeMode': 'system',
    'skin': 'classic',
    'appearanceUpdatedAt': DateTime.utc(1970).toIso8601String(),
  };
}
