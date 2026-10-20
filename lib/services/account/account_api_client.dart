import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/account_snapshot.dart';
import 'account_storage.dart';

class RemoteAccountData {
  const RemoteAccountData({
    required this.revision,
    required this.snapshot,
    this.displayName,
  });

  final int revision;
  final AccountSnapshot snapshot;
  final String? displayName;
}

class AccountApiException implements Exception {
  const AccountApiException(
    this.message, {
    this.statusCode,
    this.offline = false,
    this.conflict,
  });

  final String message;
  final int? statusCode;
  final bool offline;
  final RemoteAccountData? conflict;

  @override
  String toString() => message;
}

/// HTTP client for the StackFit account server.
class AccountApiClient {
  AccountApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = _trimUrl(baseUrl),
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;
  static const _timeout = Duration(seconds: 8);

  void close() => _httpClient.close();

  Future<AccountSession> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _auth('/v1/auth/signup', {
      'email': email,
      'password': password,
      'displayName': displayName,
    });
  }

  Future<AccountSession> signIn({
    required String email,
    required String password,
  }) {
    return _auth('/v1/auth/signin', {
      'email': email,
      'password': password,
    });
  }

  Future<void> signOut(String token) async {
    await _send(
      'POST',
      '/v1/auth/signout',
      token: token,
      offlineMessage: 'Signed out on this device.',
    );
  }

  Future<void> requestPasswordReset(String email) async {
    await _send(
      'POST',
      '/v1/auth/request-reset',
      body: {'email': email},
      offlineMessage: 'A connection is required to reset your password.',
    );
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _send(
      'POST',
      '/v1/auth/reset',
      body: {
        'email': email,
        'code': code,
        'password': password,
      },
      offlineMessage: 'A connection is required to reset your password.',
    );
  }

  Future<String?> updateDisplayName({
    required String token,
    required String displayName,
  }) async {
    final decoded = await _send(
      'PATCH',
      '/v1/profile',
      token: token,
      body: {'displayName': displayName},
      offlineMessage: 'A connection is required to update your name.',
    );
    return _cleanName(decoded['displayName'] as String?);
  }

  Future<RemoteAccountData> fetchData(String token) async {
    final decoded = await _send(
      'GET',
      '/v1/sync',
      token: token,
      offlineMessage: 'Offline — will save when online',
    );
    return _remoteFromJson(decoded);
  }

  Future<RemoteAccountData> putData({
    required String token,
    required int baseRevision,
    required AccountSnapshot snapshot,
  }) async {
    final decoded = await _send(
      'PUT',
      '/v1/sync',
      token: token,
      body: {
        'baseRevision': baseRevision,
        'snapshot': snapshot.toJson(),
      },
      offlineMessage: 'Offline — will save when online',
    );
    return _remoteFromJson(decoded);
  }

  Future<AccountSession> _auth(String path, Map<String, dynamic> body) async {
    final decoded = await _send(
      'POST',
      path,
      body: body,
      offlineMessage:
          'A connection is required to sign in. Start the account server and try again.',
    );
    final token = decoded['token'] as String?;
    final user = decoded['user'];
    if (token == null || user is! Map) {
      throw const AccountApiException('The account server sent an unexpected response.');
    }
    final userMap = Map<String, dynamic>.from(user);
    return AccountSession(
      userId: userMap['id'] as String,
      email: userMap['email'] as String,
      token: token,
      displayName: _cleanName(userMap['displayName'] as String?),
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    required String offlineMessage,
  }) async {
    try {
      final response = await _httpClient
          .send(_request(method, path, token: token, body: body))
          .timeout(_timeout);
      final raw = await response.stream.bytesToString();
      final decoded = _decodeObject(raw);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      throw AccountApiException(
        decoded['message'] as String? ?? 'Something went wrong.',
        statusCode: response.statusCode,
        conflict: response.statusCode == 409 ? _remoteFromJson(decoded) : null,
      );
    } on AccountApiException {
      rethrow;
    } on TimeoutException {
      throw AccountApiException(offlineMessage, offline: true);
    } on SocketException {
      throw AccountApiException(offlineMessage, offline: true);
    } on http.ClientException {
      throw AccountApiException(offlineMessage, offline: true);
    } catch (_) {
      throw const AccountApiException('Something went wrong.');
    }
  }

  http.Request _request(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'));
    request.headers['content-type'] = 'application/json';
    if (token != null) {
      request.headers['authorization'] = 'Bearer $token';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }
    return request;
  }

  Map<String, dynamic> _decodeObject(String raw) {
    if (raw.isEmpty) {
      return {};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return {};
  }

  RemoteAccountData _remoteFromJson(Map<String, dynamic> json) {
    final snapshotRaw = json['snapshot'];
    final snapshot = snapshotRaw is Map
        ? AccountSnapshot.fromJson(Map<String, dynamic>.from(snapshotRaw))
        : AccountSnapshot.empty();
    return RemoteAccountData(
      revision: json['revision'] as int? ?? 0,
      snapshot: snapshot,
      displayName: _cleanName(json['displayName'] as String?),
    );
  }
}

String _trimUrl(String url) {
  if (url.endsWith('/')) {
    return url.substring(0, url.length - 1);
  }
  return url;
}

String? _cleanName(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
