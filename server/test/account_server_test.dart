import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:stackfit_server/account_handler.dart';
import 'package:stackfit_server/account_store.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  String? resetCode;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('stackfit-accounts');
    final store = AccountStore(File('${directory.path}/accounts.json'));
    await store.load();
    resetCode = null;
    server = await shelf_io.serve(
      createAccountHandler(
        store,
        onResetCode: (email, code) => resetCode = code,
      ),
      InternetAddress.loopbackIPv4,
      0,
    );
    baseUrl = 'http://${server.address.host}:${server.port}';
    addTearDown(() async {
      await server.close(force: true);
      await directory.delete(recursive: true);
    });
  });

  test('signup signin and sync stay on that account', () async {
    final client = http.Client();
    addTearDown(client.close);

    final created = await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'Mia@example.com',
      'password': 'password1',
      'displayName': 'Mia',
    });
    expect(created.statusCode, 200);
    final createdBody = _json(created);
    final token = createdBody['token'] as String;
    expect((createdBody['user'] as Map)['email'], 'mia@example.com');

    final wrong = await _post(client, '$baseUrl/v1/auth/signin', {
      'email': 'mia@example.com',
      'password': 'nope',
    });
    expect(wrong.statusCode, 401);

    final snapshot = {
      'workouts': [
        {'id': 'w1', 'name': 'Push'},
      ],
      'deletedWorkouts': <dynamic>[],
      'sessions': [
        {'id': 's1', 'workoutName': 'Push'},
      ],
      'themeMode': 'dark',
      'skin': 'forest',
      'appearanceUpdatedAt': '2026-05-01T00:00:00.000Z',
    };
    final saved = await _put(client, '$baseUrl/v1/sync', token, {
      'baseRevision': 0,
      'snapshot': snapshot,
    });
    expect(saved.statusCode, 200);
    expect(_json(saved)['revision'], 1);

    final conflict = await _put(client, '$baseUrl/v1/sync', token, {
      'baseRevision': 0,
      'snapshot': snapshot,
    });
    expect(conflict.statusCode, 409);

    final other = await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'other@example.com',
      'password': 'password1',
    });
    final otherToken = _json(other)['token'] as String;
    final otherData = await client.get(
      Uri.parse('$baseUrl/v1/sync'),
      headers: {'authorization': 'Bearer $otherToken'},
    );
    expect(otherData.statusCode, 200);
    final otherSnapshot = _json(otherData)['snapshot'] as Map;
    expect(otherSnapshot['workouts'], isEmpty);
  });

  test('reset code from the server sets a new password', () async {
    final client = http.Client();
    addTearDown(client.close);

    await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'mia@example.com',
      'password': 'password1',
    });
    final requested = await _post(client, '$baseUrl/v1/auth/request-reset', {
      'email': 'mia@example.com',
    });
    expect(requested.statusCode, 200);
    expect(resetCode, isNotNull);

    final reset = await _post(client, '$baseUrl/v1/auth/reset', {
      'email': 'mia@example.com',
      'code': resetCode,
      'password': 'new-password',
    });
    expect(reset.statusCode, 200);

    final signedIn = await _post(client, '$baseUrl/v1/auth/signin', {
      'email': 'mia@example.com',
      'password': 'new-password',
    });
    expect(signedIn.statusCode, 200);
  });
}

Future<http.Response> _post(
  http.Client client,
  String url,
  Map<String, dynamic> body,
) {
  return client.post(
    Uri.parse(url),
    headers: {'content-type': 'application/json'},
    body: jsonEncode(body),
  );
}

Future<http.Response> _put(
  http.Client client,
  String url,
  String token,
  Map<String, dynamic> body,
) {
  return client.put(
    Uri.parse(url),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );
}

Map<String, dynamic> _json(http.Response response) {
  return jsonDecode(response.body) as Map<String, dynamic>;
}
