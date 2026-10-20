import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:stackfit_server/account_store.dart';
import 'package:stackfit_server/app_handler.dart';
import 'package:stackfit_server/share_store.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late String baseUrl;

  setUp(() async {
    final directory = await Directory.systemTemp.createTemp('stackfit-shares');
    final website = await Directory.systemTemp.createTemp('stackfit-share-site');
    await File('${website.path}/index.html').writeAsString('<p>StackFit</p>');
    final accounts = AccountStore(File('${directory.path}/accounts.json'));
    final shares = ShareStore(File('${directory.path}/shares.json'));
    await accounts.load();
    await shares.load();
    server = await shelf_io.serve(
      createAppHandler(accounts, shares: shares, websiteDirectory: website),
      InternetAddress.loopbackIPv4,
      0,
    );
    baseUrl = 'http://${server.address.host}:${server.port}';
    addTearDown(() async {
      await server.close(force: true);
      await directory.delete(recursive: true);
      await website.delete(recursive: true);
    });
  });

  test('a workout link is public and can be turned off', () async {
    final client = http.Client();
    addTearDown(client.close);

    final created = await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'mia@example.com',
      'password': 'password1',
    });
    final token = _json(created)['token'] as String;
    await _put(client, '$baseUrl/v1/sync', token, {
      'baseRevision': 0,
      'snapshot': _snapshot(),
    });

    final shared = await _post(client, '$baseUrl/v1/shares', {
      'kind': 'workout',
      'workoutId': 'w1',
    }, token: token);
    expect(shared.statusCode, 200);
    final shareToken = _json(shared)['token'] as String;

    final page = await client.get(Uri.parse('$baseUrl/v1/shares/$shareToken'));
    expect(page.statusCode, 200);
    expect(page.body, contains('Push day'));
    expect(page.body, isNot(contains('mia@example.com')));

    final again = await _post(client, '$baseUrl/v1/shares', {
      'kind': 'workout',
      'workoutId': 'w1',
    }, token: token);
    expect(_json(again)['token'], shareToken);

    final other = await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'other@example.com',
      'password': 'password1',
    });
    final otherToken = _json(other)['token'] as String;
    final blocked = await _post(
      client,
      '$baseUrl/v1/shares/$shareToken/disable',
      {},
      token: otherToken,
    );
    expect(blocked.statusCode, 404);

    final disabled = await _post(
      client,
      '$baseUrl/v1/shares/$shareToken/disable',
      {},
      token: token,
    );
    expect(disabled.statusCode, 200);
    final hidden = await client.get(Uri.parse('$baseUrl/v1/shares/$shareToken'));
    expect(hidden.statusCode, 404);
    expect(hidden.body, contains('This link is turned off.'));
  });

  test('a progress link lists only the chosen sessions', () async {
    final client = http.Client();
    addTearDown(client.close);
    final created = await _post(client, '$baseUrl/v1/auth/signup', {
      'email': 'mia@example.com',
      'password': 'password1',
    });
    final token = _json(created)['token'] as String;
    await _put(client, '$baseUrl/v1/sync', token, {
      'baseRevision': 0,
      'snapshot': _snapshot(),
    });

    final shared = await _post(client, '$baseUrl/v1/shares', {
      'kind': 'progress',
      'sessionIds': ['s1'],
    }, token: token);
    final shareToken = _json(shared)['token'] as String;
    final page = _json(await client.get(Uri.parse('$baseUrl/v1/shares/$shareToken')));
    final sessions = page['sessions'] as List;
    expect(sessions, hasLength(1));
    expect((sessions.single as Map)['workoutName'], 'Push day');
    expect(page.containsKey('email'), isFalse);
  });
}

Map<String, dynamic> _snapshot() {
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
    'sessions': [
      {
        'id': 's1',
        'workoutName': 'Push day',
        'completedAt': '2026-10-11T18:00:00.000Z',
        'durationSeconds': 1500,
        'totalExercises': 1,
      },
      {
        'id': 's2',
        'workoutName': 'Other',
        'completedAt': '2026-10-10T18:00:00.000Z',
        'durationSeconds': 600,
        'totalExercises': 2,
      },
    ],
    'themeMode': 'system',
    'skin': 'classic',
    'appearanceUpdatedAt': '1970-01-01T00:00:00.000Z',
  };
}

Future<http.Response> _post(
  http.Client client,
  String url,
  Map<String, dynamic> body, {
  String? token,
}) {
  return client.post(
    Uri.parse(url),
    headers: {
      'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    },
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
