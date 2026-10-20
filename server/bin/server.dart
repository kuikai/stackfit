import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:stackfit_server/account_store.dart';
import 'package:stackfit_server/app_handler.dart';
import 'package:stackfit_server/share_store.dart';

/// Local StackFit accounts. Run from the `server/` directory:
/// `dart run bin/server.dart`
Future<void> main() async {
  final dataFile = File('data/stackfit_accounts.json');
  final store = AccountStore(dataFile);
  final shares = ShareStore(File('data/stackfit_shares.json'));
  await store.load();
  await shares.load();

  final website = findWebsiteDirectory();
  final server = await shelf_io.serve(
    createAppHandler(
      store,
      shares: shares,
      websiteDirectory: website,
      onResetCode: (email, code) {
        stdout.writeln('Password reset code for $email: $code');
      },
    ),
    InternetAddress.anyIPv4,
    8787,
  );

  stdout.writeln('StackFit account server');
  stdout.writeln('Listening on http://${server.address.host}:${server.port}');
  stdout.writeln('This computer can use http://127.0.0.1:${server.port}');
  if (website == null) {
    stdout.writeln('Website folder was not found. API only.');
  } else {
    stdout.writeln('Website: http://127.0.0.1:${server.port}');
  }
  stdout.writeln('Data file: ${dataFile.absolute.path}');
  stdout.writeln(
    'Password reset codes print here. This server does not send email yet.',
  );
}
