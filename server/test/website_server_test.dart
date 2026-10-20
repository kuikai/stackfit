import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:stackfit_server/account_store.dart';
import 'package:stackfit_server/app_handler.dart';
import 'package:test/test.dart';

void main() {
  test('the website is served without hiding the API', () async {
    final accounts = await Directory.systemTemp.createTemp('stackfit-accounts');
    final website = await Directory.systemTemp.createTemp('stackfit-website');
    await File('${website.path}/index.html').writeAsString(
      '<!DOCTYPE html><title>StackFit</title><p>StackFit website</p>',
    );
    final store = AccountStore(File('${accounts.path}/accounts.json'));
    await store.load();
    final server = await shelf_io.serve(
      createAppHandler(store, websiteDirectory: website),
      InternetAddress.loopbackIPv4,
      0,
    );
    final client = http.Client();
    addTearDown(() async {
      client.close();
      await server.close(force: true);
      await accounts.delete(recursive: true);
      await website.delete(recursive: true);
    });

    final baseUrl = 'http://${server.address.host}:${server.port}';
    final page = await client.get(Uri.parse('$baseUrl/'));
    expect(page.statusCode, 200);
    expect(page.body, contains('StackFit website'));

    final health = await client.get(Uri.parse('$baseUrl/v1/health'));
    expect(health.statusCode, 200);
    expect(health.body, contains('"ok":true'));

    final sharePage = await client.get(
      Uri.parse('$baseUrl/s/0123456789abcdef'),
    );
    expect(sharePage.statusCode, 200);
    expect(sharePage.body, contains('StackFit website'));

    final tabata = await client.get(Uri.parse('$baseUrl/tabata'));
    expect(tabata.statusCode, 200);
    expect(tabata.body, contains('StackFit website'));
  });
}
