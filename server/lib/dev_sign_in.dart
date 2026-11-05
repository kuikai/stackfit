import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import 'account_handler.dart';
import 'account_store.dart';

/// Signs in the local developer account. Refuses any request that did not
/// come from this computer, so the open port is not a passwordless login.
Future<Response> devSignIn(Request request, AccountStore store) async {
  if (!requestIsFromThisComputer(request)) {
    return Response.notFound('Not found.');
  }
  final user = await store.developerAccount();
  final token = await store.issueToken(user.id);
  return Response(
    200,
    body: jsonEncode({'token': token, 'user': user.toJson()}),
    headers: jsonHeaders,
  );
}

bool requestIsFromThisComputer(Request request) {
  final info = request.context['shelf.io.connection_info'];
  if (info is! HttpConnectionInfo) {
    return false;
  }
  return info.remoteAddress.isLoopback;
}
