import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:stackfit_server/account_handler.dart';
import 'package:stackfit_server/account_store.dart';
import 'package:stackfit_server/share_store.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  String? resetCode;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp(
      'stackfit-accounts',
    );
    final store = AccountStore(File('${directory.path}/accounts.json'));
    await store.load();
    final shares = ShareStore(File('${directory.path}/shares.json'));
    await shares.load();
    resetCode = null;
    server = await shelf_io.serve(
      createAccountHandler(
        store,
        shares: shares,
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

  test('deleting an account removes its workouts and share links', () async {
    final client = http.Client();
    addTearDown(client.close);
    final token = await _token(client, baseUrl, 'mia@example.com');
    final other = await _token(client, baseUrl, 'other@example.com');
    await _put(client, '$baseUrl/v1/sync', token, {
      'baseRevision': 0,
      'snapshot': _workoutSnapshot(),
    });
    final shared = await _postAuth(client, '$baseUrl/v1/shares', {
      'kind': 'workout',
      'workoutId': 'w1',
    }, token);
    expect(shared.statusCode, 200);
    final shareToken = _json(shared)['token'] as String;

    final wrong = await _delete(client, baseUrl, token, {'password': 'nope'});
    expect(wrong.statusCode, 401);
    final stillShared = await client.get(
      Uri.parse('$baseUrl/v1/shares/$shareToken'),
    );
    expect(stillShared.statusCode, 200);

    final deleted = await _delete(client, baseUrl, token, {
      'password': 'password1',
    });
    expect(deleted.statusCode, 200);
    final gone = await client.get(
      Uri.parse('$baseUrl/v1/sync'),
      headers: {'authorization': 'Bearer $token'},
    );
    expect(gone.statusCode, 401);
    final page = await client.get(Uri.parse('$baseUrl/v1/shares/$shareToken'));
    expect(page.statusCode, 404);
    final signedIn = await _post(client, '$baseUrl/v1/auth/signin', {
      'email': 'mia@example.com',
      'password': 'password1',
    });
    expect(signedIn.statusCode, 401);
    final again = await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'mia@example.com',
      'password': 'password1',
    });
    expect(again.statusCode, 200);
    final otherData = await client.get(
      Uri.parse('$baseUrl/v1/sync'),
      headers: {'authorization': 'Bearer $other'},
    );
    expect(otherData.statusCode, 200);
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

Future<String> _token(http.Client client, String baseUrl, String email) async {
  final created = await _post(client, '$baseUrl/v1/auth/signup', {
    'email': email,
    'password': 'password1',
  });
  expect(created.statusCode, 200);
  return _json(created)['token'] as String;
}

Future<http.Response> _postAuth(
  http.Client client,
  String url,
  Map<String, dynamic> body,
  String token,
) {
  return client.post(
    Uri.parse(url),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );
}

Future<http.Response> _delete(
  http.Client client,
  String baseUrl,
  String token,
  Map<String, dynamic> body,
) {
  return client.delete(
    Uri.parse('$baseUrl/v1/account'),
    headers: {
      'content-type': 'application/json',
      'authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );
}

Map<String, dynamic> _workoutSnapshot() {
  return {
    'workouts': [
      {
        'id': 'w1',
        'name': 'Push day',
        'exercises': [
          {
            'name': 'Bench press',
            'type': 'sets',
            'sets': 4,
            'reps': 8,
            'restSeconds': 90,
          },
        ],
      },
    ],
    'deletedWorkouts': <dynamic>[],
    'sessions': <dynamic>[],
    'themeMode': 'system',
    'skin': 'classic',
    'appearanceUpdatedAt': '1970-01-01T00:00:00.000Z',
  };
}
