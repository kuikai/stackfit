import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'account_handler.dart';
import 'account_store.dart';
import 'share_store.dart';

void mountShareRoutes(Router router, AccountStore accounts, ShareStore shares) {
  router
    ..get('/v1/shares', (Request request) => _listShares(request, accounts, shares))
    ..post('/v1/shares', (Request request) => _createShare(request, accounts, shares))
    ..get('/v1/shares/<token>', (Request request, String token) => _readShare(shares, token))
    ..post(
      '/v1/shares/<token>/disable',
      (Request request, String token) => _disableShare(request, accounts, shares, token),
    );
}

Future<Response> _listShares(
  Request request,
  AccountStore accounts,
  ShareStore shares,
) async {
  final user = await _owner(request, accounts);
  if (user == null) {
    return _error(401, 'Sign in again.');
  }
  final links = await shares.listEnabled(user.id);
  return _ok({
    'shares': [for (final link in links) link.toOwnerJson()],
  });
}

Future<Response> _readShare(ShareStore shares, String token) async {
  if (!_validToken(token)) {
    return _error(404, 'This link is turned off.');
  }
  final share = await shares.publicShare(token);
  if (share == null) {
    return _error(404, 'This link is turned off.');
  }
  return _ok(share.toPublicJson());
}

Future<Response> _disableShare(
  Request request,
  AccountStore accounts,
  ShareStore shares,
  String token,
) async {
  final user = await _owner(request, accounts);
  if (user == null) {
    return _error(401, 'Sign in again.');
  }
  final disabled = await shares.disable(ownerId: user.id, token: token);
  if (!disabled) {
    return _error(404, 'This link is turned off.');
  }
  return _ok({'ok': true});
}

Future<Response> _createShare(
  Request request,
  AccountStore accounts,
  ShareStore shares,
) async {
  final user = await _owner(request, accounts);
  if (user == null) {
    return _error(401, 'Sign in again.');
  }
  try {
    final body = await _readBody(request);
    final data = await accounts.readData(user.id);
    if (body['kind'] == 'workout') {
      return _shareWorkout(shares, user, data.snapshot, body);
    }
    if (body['kind'] == 'progress') {
      return _shareProgress(shares, user, data.snapshot, body);
    }
    return _error(400, 'Choose a workout or a progress summary.');
  } on FormatException {
    return _error(400, 'Send the share as JSON.');
  }
}

Future<Response> _shareWorkout(
  ShareStore shares,
  StoredUser user,
  Map<String, dynamic> snapshot,
  Map<String, dynamic> body,
) async {
  final workoutId = body['workoutId'];
  if (workoutId is! String || workoutId.isEmpty) {
    return _error(400, 'Choose a workout to share.');
  }
  final workout = publicWorkout(snapshot, workoutId);
  if (workout == null) {
    return _error(400, 'Add at least one exercise before sharing.');
  }
  final saved = await shares.saveWorkout(
    ownerId: user.id,
    workoutId: workoutId,
    title: workout['name'] as String,
    body: workout,
  );
  return _ok(_created(saved));
}

Future<Response> _shareProgress(
  ShareStore shares,
  StoredUser user,
  Map<String, dynamic> snapshot,
  Map<String, dynamic> body,
) async {
  final ids = body['sessionIds'];
  if (ids is! List || ids.isEmpty) {
    return _error(400, 'Choose at least one session.');
  }
  final sessions = publicSessions(snapshot, ids.whereType<String>().toList());
  if (sessions.isEmpty) {
    return _error(400, 'Choose at least one session.');
  }
  final saved = await shares.saveProgress(
    ownerId: user.id,
    title: 'Progress',
    body: {'sessions': sessions},
  );
  return _ok(_created(saved));
}

Map<String, dynamic>? publicWorkout(Map<String, dynamic> snapshot, String workoutId) {
  final workouts = snapshot['workouts'];
  if (workouts is! List) {
    return null;
  }
  for (final item in workouts.whereType<Map<Object?, Object?>>()) {
    final workout = Map<String, dynamic>.from(item);
    if (workout['id'] != workoutId) {
      continue;
    }
    return _sanitizeWorkout(workout);
  }
  return null;
}

List<Map<String, dynamic>> publicSessions(
  Map<String, dynamic> snapshot,
  List<String> sessionIds,
) {
  final wanted = sessionIds.toSet();
  final sessions = snapshot['sessions'];
  if (sessions is! List) {
    return const [];
  }
  final result = <Map<String, dynamic>>[];
  for (final item in sessions.whereType<Map<Object?, Object?>>()) {
    final session = Map<String, dynamic>.from(item);
    final id = session['id'];
    if (id is! String || !wanted.contains(id)) {
      continue;
    }
    final public = _sanitizeSession(session);
    if (public != null) {
      result.add(public);
    }
  }
  return result;
}

Map<String, dynamic>? _sanitizeWorkout(Map<String, dynamic> workout) {
  final name = workout['name'];
  final exercises = workout['exercises'];
  if (name is! String || name.trim().isEmpty || exercises is! List || exercises.isEmpty) {
    return null;
  }
  final publicExercises = <Map<String, dynamic>>[];
  for (final item in exercises.whereType<Map<Object?, Object?>>()) {
    final exercise = _sanitizeExercise(Map<String, dynamic>.from(item));
    if (exercise == null) {
      return null;
    }
    publicExercises.add(exercise);
  }
  return {'name': name.trim(), 'exercises': publicExercises};
}

Map<String, dynamic>? _sanitizeExercise(Map<String, dynamic> exercise) {
  final name = exercise['name'];
  final type = exercise['type'];
  if (name is! String || name.trim().isEmpty) {
    return null;
  }
  if (type == 'timer') {
    return _timerExercise(name.trim(), exercise);
  }
  if (type == 'sets') {
    return _setsExercise(name.trim(), exercise);
  }
  return null;
}

Map<String, dynamic>? _timerExercise(String name, Map<String, dynamic> exercise) {
  final work = exercise['workSeconds'];
  final rest = exercise['restSeconds'];
  final sets = exercise['sets'];
  if (work is! int || work < 1 || rest is! int || rest < 0 || sets is! int || sets < 1) {
    return null;
  }
  return {
    'name': name,
    'type': 'timer',
    'workSeconds': work,
    'restSeconds': rest,
    'sets': sets,
    'reps': null,
  };
}

Map<String, dynamic>? _setsExercise(String name, Map<String, dynamic> exercise) {
  final sets = exercise['sets'];
  final rest = exercise['restSeconds'];
  final reps = exercise['reps'];
  if (sets is! int || sets < 1 || rest is! int || rest < 0) {
    return null;
  }
  if (reps != null && (reps is! int || reps < 1)) {
    return null;
  }
  return {
    'name': name,
    'type': 'sets',
    'workSeconds': null,
    'restSeconds': rest,
    'sets': sets,
    'reps': reps,
  };
}

Map<String, dynamic>? _sanitizeSession(Map<String, dynamic> session) {
  final name = session['workoutName'];
  final completedAt = session['completedAt'];
  final duration = session['durationSeconds'];
  final total = session['totalExercises'];
  final when = completedAt is String ? DateTime.tryParse(completedAt) : null;
  if (name is! String || name.trim().isEmpty || when == null) {
    return null;
  }
  if (duration is! int || duration < 0 || total is! int || total < 0) {
    return null;
  }
  return {
    'workoutName': name.trim(),
    'completedAt': when.toUtc().toIso8601String(),
    'durationSeconds': duration,
    'totalExercises': total,
  };
}

Map<String, dynamic> _created(StoredShare share) {
  return {
    'token': share.token,
    'kind': share.kind,
    'path': '/s/${share.token}',
  };
}

Future<StoredUser?> _owner(Request request, AccountStore accounts) async {
  final token = bearerToken(request);
  if (token == null) {
    return null;
  }
  return accounts.userForToken(token);
}

Future<Map<String, dynamic>> _readBody(Request request) async {
  final raw = await request.readAsString();
  if (raw.length > 2000000) {
    throw const FormatException('Body is too large.');
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return Map<String, dynamic>.from(decoded);
}

bool _validToken(String token) {
  return RegExp(r'^[a-f0-9]{16,64}$').hasMatch(token);
}

Response _ok(Map<String, dynamic> body) {
  return Response.ok(jsonEncode(body), headers: jsonHeaders);
}

Response _error(int status, String message) {
  return Response(
    status,
    body: jsonEncode({'message': message}),
    headers: jsonHeaders,
  );
}
