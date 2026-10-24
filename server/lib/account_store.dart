import 'dart:convert';
import 'dart:io';

import 'password_hash.dart';

class StoredUser {
  const StoredUser({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
    };
  }
}

class StoredData {
  const StoredData({
    required this.revision,
    required this.snapshot,
    required this.displayName,
  });

  final int revision;
  final Map<String, dynamic> snapshot;
  final String? displayName;
}

class RevisionConflict implements Exception {
  const RevisionConflict(this.current);

  final StoredData current;
}

class AccountStore {
  AccountStore(this._file);

  final File _file;
  final Map<String, _UserRecord> _usersById = {};
  final Map<String, String> _userIdByEmail = {};
  final Map<String, String> _userIdByTokenHash = {};
  final Map<String, _ResetRecord> _resetsByUserId = {};
  final Map<String, _DataRecord> _dataByUserId = {};

  Future<void> _queue = Future<void>.value();

  Future<T> _sync<T>(Future<T> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> load() {
    return _sync(() async {
      if (!await _file.exists()) {
        await _file.parent.create(recursive: true);
        await _writeFile();
        return;
      }
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Account data file is not an object.');
      }
      _readUsers(decoded['users']);
      _readTokens(decoded['tokens']);
      _readResets(decoded['resets']);
      _readData(decoded['data']);
    });
  }

  Future<StoredUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _sync(() async {
      final normalized = normalizeEmail(email);
      if (_userIdByEmail.containsKey(normalized)) {
        throw const AccountStoreException(
          'An account with that email already exists.',
        );
      }
      final user = _UserRecord(
        id: randomHex(16),
        email: normalized,
        passwordHash: hashPassword(password),
        displayName: cleanDisplayName(displayName),
        createdAt: DateTime.now().toUtc(),
      );
      _usersById[user.id] = user;
      _userIdByEmail[user.email] = user.id;
      _dataByUserId[user.id] = _DataRecord(
        revision: 0,
        snapshot: emptySnapshot(),
      );
      await _writeFile();
      return user.view();
    });
  }

  Future<StoredUser> signIn({
    required String email,
    required String password,
  }) {
    return _sync(() async {
      final user = _usersById[_userIdByEmail[normalizeEmail(email)]];
      if (user == null || !verifyPassword(password, user.passwordHash)) {
        throw const AccountStoreException('Email or password is incorrect.');
      }
      return user.view();
    });
  }

  Future<String> issueToken(String userId) {
    return _sync(() async {
      final token = randomHex(32);
      _userIdByTokenHash[sha256Hex(token)] = userId;
      await _writeFile();
      return token;
    });
  }

  Future<void> revokeToken(String token) {
    return _sync(() async {
      _userIdByTokenHash.remove(sha256Hex(token));
      await _writeFile();
    });
  }

  Future<StoredUser?> userForToken(String token) {
    return _sync(() async {
      final userId = _userIdByTokenHash[sha256Hex(token)];
      return _usersById[userId]?.view();
    });
  }

  Future<String?> requestReset(String email) {
    return _sync(() async {
      final user = _usersById[_userIdByEmail[normalizeEmail(email)]];
      if (user == null) {
        return null;
      }
      final code = _resetCode();
      _resetsByUserId[user.id] = _ResetRecord(
        codeHash: sha256Hex(code),
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 30)),
      );
      await _writeFile();
      return code;
    });
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) {
    return _sync(() async {
      final user = _usersById[_userIdByEmail[normalizeEmail(email)]];
      final reset = user == null ? null : _resetsByUserId[user.id];
      final expired = reset != null && !reset.expiresAt.isAfter(DateTime.now().toUtc());
      final matches = reset != null && reset.codeHash == sha256Hex(code.trim());
      if (user == null || reset == null || expired || !matches) {
        throw const AccountStoreException('Reset code is incorrect or expired.');
      }
      _usersById[user.id] = user.copyWith(passwordHash: hashPassword(password));
      _resetsByUserId.remove(user.id);
      await _writeFile();
    });
  }

  Future<StoredUser> updateDisplayName({
    required String userId,
    required String displayName,
  }) {
    return _sync(() async {
      final user = _requireUser(userId);
      final updated = user.copyWith(
        displayName: cleanDisplayName(displayName),
        clearDisplayName: cleanDisplayName(displayName) == null,
      );
      _usersById[userId] = updated;
      await _writeFile();
      return updated.view();
    });
  }

  Future<StoredData> readData(String userId) {
    return _sync(() async {
      final user = _requireUser(userId);
      final data = _dataByUserId[userId] ??
          _DataRecord(revision: 0, snapshot: emptySnapshot());
      return StoredData(
        revision: data.revision,
        snapshot: data.snapshot,
        displayName: user.displayName,
      );
    });
  }

  Future<StoredData> writeData({
    required String userId,
    required int baseRevision,
    required Map<String, dynamic> snapshot,
  }) {
    return _sync(() async {
      final user = _requireUser(userId);
      final current = _dataByUserId[userId] ??
          _DataRecord(revision: 0, snapshot: emptySnapshot());
      if (current.revision != baseRevision) {
        throw RevisionConflict(
          StoredData(
            revision: current.revision,
            snapshot: current.snapshot,
            displayName: user.displayName,
          ),
        );
      }
      final saved = _DataRecord(
        revision: current.revision + 1,
        snapshot: snapshot,
      );
      _dataByUserId[userId] = saved;
      await _writeFile();
      return StoredData(
        revision: saved.revision,
        snapshot: saved.snapshot,
        displayName: user.displayName,
      );
    });
  }

  _UserRecord _requireUser(String userId) {
    final user = _usersById[userId];
    if (user == null) {
      throw const AccountStoreException('Sign in again.');
    }
    return user;
  }

  String _resetCode() {
    final number = _randomSixDigits();
    return number.toString().padLeft(6, '0');
  }

  int _randomSixDigits() {
    final bytes = randomHex(3);
    final value = int.parse(bytes, radix: 16);
    return value % 1000000;
  }

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

  Future<void> _writeFile() async {
    final payload = {
      'users': _usersById.values.map((user) => user.toJson()).toList(),
      'tokens': [
        for (final entry in _userIdByTokenHash.entries)
          {'tokenHash': entry.key, 'userId': entry.value},
      ],
      'resets': [
        for (final entry in _resetsByUserId.entries)
          {
            'userId': entry.key,
            'codeHash': entry.value.codeHash,
            'expiresAt': entry.value.expiresAt.toIso8601String(),
          },
      ],
      'data': {
        for (final entry in _dataByUserId.entries)
          entry.key: {
            'revision': entry.value.revision,
            'snapshot': entry.value.snapshot,
          },
      },
    };
    await _file.parent.create(recursive: true);
    await _file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
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
  const _ResetRecord({
    required this.codeHash,
    required this.expiresAt,
  });

  final String codeHash;
  final DateTime expiresAt;
}

class _DataRecord {
  const _DataRecord({
    required this.revision,
    required this.snapshot,
  });

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
