import 'dart:convert';
import 'dart:io';

import 'password_hash.dart';

class StoredShare {
  const StoredShare({
    required this.token,
    required this.ownerId,
    required this.kind,
    required this.enabled,
    required this.sourceId,
    required this.title,
    required this.body,
  });

  final String token;
  final String ownerId;
  final String kind;
  final bool enabled;
  final String sourceId;
  final String title;
  final Map<String, dynamic> body;

  Map<String, dynamic> toPublicJson() {
    return {'token': token, 'kind': kind, ...body};
  }

  Map<String, dynamic> toOwnerJson() {
    return {
      'token': token,
      'kind': kind,
      'sourceId': sourceId,
      'title': title,
      'enabled': enabled,
    };
  }
}

/// Public workout and progress links. Separate from account passwords.
class ShareStore {
  ShareStore(this._file);

  final File _file;
  final Map<String, _ShareRecord> _byToken = {};
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
        throw const FormatException('Share file is not an object.');
      }
      _readShares(decoded['shares']);
    });
  }

  Future<StoredShare?> publicShare(String token) {
    return _sync(() async {
      final share = _byToken[token];
      if (share == null || !share.enabled) {
        return null;
      }
      return share.view();
    });
  }

  Future<List<StoredShare>> listEnabled(String ownerId) {
    return _sync(() async {
      return [
        for (final share in _byToken.values)
          if (share.ownerId == ownerId && share.enabled) share.view(),
      ];
    });
  }

  Future<StoredShare> saveWorkout({
    required String ownerId,
    required String workoutId,
    required String title,
    required Map<String, dynamic> body,
  }) {
    return _save(
      ownerId: ownerId,
      kind: 'workout',
      sourceId: workoutId,
      title: title,
      body: body,
    );
  }

  Future<StoredShare> saveProgress({
    required String ownerId,
    required String title,
    required Map<String, dynamic> body,
  }) {
    return _save(
      ownerId: ownerId,
      kind: 'progress',
      sourceId: 'progress',
      title: title,
      body: body,
    );
  }

  Future<bool> disable({required String ownerId, required String token}) {
    return _sync(() async {
      final share = _byToken[token];
      if (share == null || share.ownerId != ownerId) {
        return false;
      }
      _byToken[token] = share.copyWith(enabled: false);
      await _writeFile();
      return true;
    });
  }

  Future<void> deleteOwned(String ownerId) {
    return _sync(() async {
      final before = _byToken.length;
      _byToken.removeWhere((_, share) => share.ownerId == ownerId);
      if (_byToken.length == before) {
        return;
      }
      await _writeFile();
    });
  }

  Future<StoredShare> _save({
    required String ownerId,
    required String kind,
    required String sourceId,
    required String title,
    required Map<String, dynamic> body,
  }) {
    return _sync(() async {
      final existing = _match(ownerId, kind, sourceId);
      final token = existing?.token ?? randomHex(12);
      _byToken[token] = _ShareRecord(
        token: token,
        ownerId: ownerId,
        kind: kind,
        enabled: true,
        sourceId: sourceId,
        title: title,
        body: body,
        updatedAt: DateTime.now().toUtc(),
      );
      await _writeFile();
      return _byToken[token]!.view();
    });
  }

  _ShareRecord? _match(String ownerId, String kind, String sourceId) {
    for (final share in _byToken.values) {
      final sameOwner = share.ownerId == ownerId && share.kind == kind;
      if (sameOwner && share.sourceId == sourceId) {
        return share;
      }
    }
    return null;
  }

  void _readShares(Object? raw) {
    if (raw is! List<dynamic>) {
      return;
    }
    for (final item in raw.whereType<Map<Object?, Object?>>()) {
      final share = _ShareRecord.fromJson(Map<String, dynamic>.from(item));
      if (share != null) {
        _byToken[share.token] = share;
      }
    }
  }

  Future<void> _writeFile() async {
    final payload = {
      'shares': [for (final share in _byToken.values) share.toJson()],
    };
    await _file.parent.create(recursive: true);
    final encoded = const JsonEncoder.withIndent('  ').convert(payload);
    await _file.writeAsString(encoded);
  }
}

class _ShareRecord {
  const _ShareRecord({
    required this.token,
    required this.ownerId,
    required this.kind,
    required this.enabled,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.updatedAt,
  });

  final String token;
  final String ownerId;
  final String kind;
  final bool enabled;
  final String sourceId;
  final String title;
  final Map<String, dynamic> body;
  final DateTime updatedAt;

  _ShareRecord copyWith({required bool enabled}) {
    return _ShareRecord(
      token: token,
      ownerId: ownerId,
      kind: kind,
      enabled: enabled,
      sourceId: sourceId,
      title: title,
      body: body,
      updatedAt: updatedAt,
    );
  }

  StoredShare view() {
    return StoredShare(
      token: token,
      ownerId: ownerId,
      kind: kind,
      enabled: enabled,
      sourceId: sourceId,
      title: title,
      body: body,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'ownerId': ownerId,
      'kind': kind,
      'enabled': enabled,
      'sourceId': sourceId,
      'title': title,
      'body': body,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static _ShareRecord? fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    final ownerId = json['ownerId'];
    final kind = json['kind'];
    final sourceId = json['sourceId'];
    final title = json['title'];
    final body = json['body'];
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (token is! String || ownerId is! String || kind is! String) {
      return null;
    }
    if (sourceId is! String ||
        title is! String ||
        body is! Map ||
        updatedAt == null) {
      return null;
    }
    return _ShareRecord(
      token: token,
      ownerId: ownerId,
      kind: kind,
      enabled: json['enabled'] == true,
      sourceId: sourceId,
      title: title,
      body: Map<String, dynamic>.from(body),
      updatedAt: updatedAt,
    );
  }
}
