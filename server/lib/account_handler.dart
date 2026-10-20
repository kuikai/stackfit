import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'account_store.dart';
import 'share_routes.dart';
import 'share_store.dart';

const jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

const corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, PUT, PATCH, OPTIONS',
  'access-control-allow-headers': 'content-type, authorization',
};

Handler createAccountHandler(
  AccountStore store, {
  ShareStore? shares,
  void Function(String email, String code)? onResetCode,
}) {
  final router = Router()
    ..get('/v1/health', _health)
    ..post('/v1/auth/signup', (Request request) => _signUp(request, store))
    ..post('/v1/auth/signin', (Request request) => _signIn(request, store))
    ..post('/v1/auth/signout', (Request request) => _signOut(request, store))
    ..post(
      '/v1/auth/request-reset',
      (Request request) => _requestReset(request, store, onResetCode),
    )
    ..post('/v1/auth/reset', (Request request) => _resetPassword(request, store))
    ..patch('/v1/profile', (Request request) => _updateProfile(request, store))
    ..get('/v1/sync', (Request request) => _readSync(request, store))
    ..put('/v1/sync', (Request request) => _writeSync(request, store));
  if (shares != null) {
    mountShareRoutes(router, store, shares);
  }

  final api = const Pipeline().addMiddleware(_cors()).addHandler(router.call);
  return (Request request) {
    if (!_isApiPath(request.url.path)) {
      return Response.notFound('Not found.');
    }
    return api(request);
  };
}

bool _isApiPath(String path) {
  return path == 'v1' || path.startsWith('v1/');
}

Middleware _cors() {
  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      final response = await inner(request);
      return response.change(headers: corsHeaders);
    };
  };
}

Response _health(Request request) {
  return _ok({'ok': true});
}

Future<Response> _signUp(Request request, AccountStore store) async {
  try {
    final body = await _readJson(request);
    final email = validEmail(body['email']);
    final password = validPassword(body['password']);
    if (email == null) {
      return _error(400, 'Enter a valid email.');
    }
    if (password == null) {
      return _error(400, 'Password must be at least 8 characters.');
    }
    final nameError = displayNameError(body['displayName']);
    if (nameError != null) {
      return _error(400, nameError);
    }
    final user = await store.signUp(
      email: email,
      password: password,
      displayName: body['displayName'] as String?,
    );
    final token = await store.issueToken(user.id);
    return _ok({'token': token, 'user': user.toJson()});
  } on AccountStoreException catch (error) {
    return _error(409, error.message);
  } on FormatException {
    return _error(400, 'Send account details as JSON.');
  }
}

Future<Response> _signIn(Request request, AccountStore store) async {
  try {
    final body = await _readJson(request);
    final email = validEmail(body['email']);
    final password = body['password'];
    if (email == null || password is! String || password.isEmpty) {
      return _error(401, 'Email or password is incorrect.');
    }
    final user = await store.signIn(email: email, password: password);
    final token = await store.issueToken(user.id);
    return _ok({'token': token, 'user': user.toJson()});
  } on AccountStoreException catch (error) {
    return _error(401, error.message);
  } on FormatException {
    return _error(400, 'Send account details as JSON.');
  }
}

Future<Response> _signOut(Request request, AccountStore store) async {
  final token = bearerToken(request);
  if (token == null) {
    return _error(401, 'Sign in again.');
  }
  await store.revokeToken(token);
  return _ok({'ok': true});
}

Future<Response> _requestReset(
  Request request,
  AccountStore store,
  void Function(String email, String code)? onResetCode,
) async {
  try {
    final body = await _readJson(request);
    final email = validEmail(body['email']);
    if (email == null) {
      return _error(400, 'Enter a valid email.');
    }
    final code = await store.requestReset(email);
    if (code != null) {
      onResetCode?.call(email, code);
    }
    return _ok({
      'message':
          'If that email has an account, the reset code was printed by the local server.',
    });
  } on FormatException {
    return _error(400, 'Send account details as JSON.');
  }
}

Future<Response> _resetPassword(Request request, AccountStore store) async {
  try {
    final body = await _readJson(request);
    final email = validEmail(body['email']);
    final password = validPassword(body['password']);
    final code = body['code'];
    if (email == null || password == null || code is! String) {
      return _error(400, 'Enter the reset code and a new password of at least 8 characters.');
    }
    await store.resetPassword(email: email, code: code, password: password);
    return _ok({'ok': true});
  } on AccountStoreException catch (error) {
    return _error(400, error.message);
  } on FormatException {
    return _error(400, 'Send account details as JSON.');
  }
}

Future<Response> _updateProfile(Request request, AccountStore store) async {
  final user = await _authorizedUser(request, store);
  if (user == null) {
    return _error(401, 'Sign in again.');
  }
  try {
    final body = await _readJson(request);
    final nameError = displayNameError(body['displayName']);
    if (nameError != null) {
      return _error(400, nameError);
    }
    final updated = await store.updateDisplayName(
      userId: user.id,
      displayName: body['displayName'] as String? ?? '',
    );
    return _ok({'user': updated.toJson(), 'displayName': updated.displayName});
  } on FormatException {
    return _error(400, 'Send account details as JSON.');
  }
}

Future<Response> _readSync(Request request, AccountStore store) async {
  final user = await _authorizedUser(request, store);
  if (user == null) {
    return _error(401, 'Sign in again.');
  }
  final data = await store.readData(user.id);
  return _ok(_dataJson(data));
}

Future<Response> _writeSync(Request request, AccountStore store) async {
  final user = await _authorizedUser(request, store);
  if (user == null) {
    return _error(401, 'Sign in again.');
  }
  try {
    final body = await _readJson(request);
    final baseRevision = body['baseRevision'];
    final snapshot = body['snapshot'];
    if (baseRevision is! int || snapshot is! Map) {
      return _error(400, 'Send the saved workouts to update.');
    }
    final saved = await store.writeData(
      userId: user.id,
      baseRevision: baseRevision,
      snapshot: Map<String, dynamic>.from(snapshot),
    );
    return _ok(_dataJson(saved));
  } on RevisionConflict catch (error) {
    return _json(409, {
      'message': 'Your account was updated somewhere else. Trying again.',
      ..._dataJson(error.current),
    });
  } on FormatException {
    return _error(400, 'Send the saved workouts as JSON.');
  }
}

Future<StoredUser?> _authorizedUser(Request request, AccountStore store) async {
  final token = bearerToken(request);
  if (token == null) {
    return null;
  }
  return store.userForToken(token);
}

Future<Map<String, dynamic>> _readJson(Request request) async {
  final raw = await request.readAsString();
  if (raw.length > 2000000) {
    throw const FormatException('Body is too large.');
  }
  if (raw.isEmpty) {
    return {};
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return Map<String, dynamic>.from(decoded);
}

Map<String, dynamic> _dataJson(StoredData data) {
  return {
    'revision': data.revision,
    'displayName': data.displayName,
    'snapshot': data.snapshot,
  };
}

Response _ok(Map<String, dynamic> body) => _json(200, body);

Response _error(int status, String message) {
  return _json(status, {'message': message});
}

Response _json(int status, Map<String, dynamic> body) {
  return Response(
    status,
    body: jsonEncode(body),
    headers: jsonHeaders,
  );
}

String? bearerToken(Request request) {
  final header = request.headers['authorization'];
  if (header == null) {
    return null;
  }
  const prefix = 'bearer ';
  if (!header.toLowerCase().startsWith(prefix)) {
    return null;
  }
  final token = header.substring(prefix.length).trim();
  if (token.isEmpty) {
    return null;
  }
  return token;
}

String? validEmail(Object? value) {
  if (value is! String) {
    return null;
  }
  final email = normalizeEmail(value);
  final at = email.indexOf('@');
  if (at <= 0 || at == email.length - 1 || email.length > 254) {
    return null;
  }
  if (!email.substring(at + 1).contains('.')) {
    return null;
  }
  return email;
}

String? validPassword(Object? value) {
  if (value is! String || value.length < 8 || value.length > 200) {
    return null;
  }
  return value;
}

String? displayNameError(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    return 'Display name must be text.';
  }
  if (value.trim().length > 40) {
    return 'Display name must be 40 characters or less.';
  }
  return null;
}
