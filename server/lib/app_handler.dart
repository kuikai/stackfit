import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_static/shelf_static.dart';

import 'account_handler.dart';
import 'account_store.dart';
import 'share_store.dart';

/// Account API plus the static site in `website/`, when that folder is present.
Handler createAppHandler(
  AccountStore store, {
  ShareStore? shares,
  Directory? websiteDirectory,
  void Function(String email, String code)? onResetCode,
}) {
  final api = createAccountHandler(
    store,
    shares: shares,
    onResetCode: onResetCode,
  );
  final directory = websiteDirectory ?? findWebsiteDirectory();
  if (directory == null) {
    return api;
  }

  final files = const Pipeline()
      .addMiddleware(_noCache())
      .addHandler(
        createStaticHandler(
          directory.path,
          defaultDocument: 'index.html',
        ),
      );
  final site = Cascade().add(_sharePage(directory)).add(files).handler;
  return (Request request) {
    if (_isApiPath(request.url.path)) {
      return api(request);
    }
    return site(request);
  };
}

/// `server/` is the usual working directory, so the site is one level up.
Directory? findWebsiteDirectory() {
  final candidates = [
    Directory.current.uri.resolve('website/'),
    Directory.current.uri.resolve('../website/'),
  ];
  for (final uri in candidates) {
    final directory = Directory.fromUri(uri);
    final index = File.fromUri(directory.uri.resolve('index.html'));
    if (index.existsSync()) {
      return directory;
    }
  }
  return null;
}

Handler _sharePage(Directory website) {
  final index = File.fromUri(website.uri.resolve('index.html'));
  return (Request request) async {
    if (!_isClientPage(request.url.path) || !index.existsSync()) {
      return Response.notFound('');
    }
    return Response.ok(
      await index.readAsString(),
      headers: const {
        'content-type': 'text/html; charset=utf-8',
        'cache-control': 'no-cache',
      },
    );
  };
}

bool _isClientPage(String path) {
  return path == 'tabata' || RegExp(r'^s/[a-f0-9]{16,64}$').hasMatch(path);
}

bool _isApiPath(String path) {
  return path == 'v1' || path.startsWith('v1/');
}

Middleware _noCache() {
  return (Handler inner) {
    return (Request request) async {
      final response = await inner(request);
      return response.change(headers: const {'cache-control': 'no-cache'});
    };
  };
}
