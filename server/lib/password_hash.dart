import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _iterations = 31000;
const _keyLength = 32;

final _random = Random.secure();

String hashPassword(String password) {
  final salt = _randomBytes(16);
  final hash = pbkdf2(
    password: utf8.encode(password),
    salt: salt,
    iterations: _iterations,
    length: _keyLength,
  );
  return 'pbkdf2\$$_iterations\$${base64Encode(salt)}\$${base64Encode(hash)}';
}

bool verifyPassword(String password, String stored) {
  final parts = stored.split('\$');
  if (parts.length != 4 || parts[0] != 'pbkdf2') {
    return false;
  }
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 1 || iterations > 500000) {
    return false;
  }
  final salt = base64Decode(parts[2]);
  final expected = base64Decode(parts[3]);
  final actual = pbkdf2(
    password: utf8.encode(password),
    salt: salt,
    iterations: iterations,
    length: expected.length,
  );
  return _fixedTimeEquals(actual, expected);
}

String randomHex(int byteCount) {
  final bytes = _randomBytes(byteCount);
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String sha256Hex(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}

Uint8List pbkdf2({
  required List<int> password,
  required List<int> salt,
  required int iterations,
  required int length,
}) {
  final hmac = Hmac(sha256, password);
  const hashLength = 32;
  final blockCount = (length / hashLength).ceil();
  final output = BytesBuilder(copy: false);

  for (var blockIndex = 1; blockIndex <= blockCount; blockIndex++) {
    var block = hmac.convert([...salt, ..._int32(blockIndex)]).bytes;
    final mixed = Uint8List.fromList(block);
    for (var round = 1; round < iterations; round++) {
      block = hmac.convert(block).bytes;
      for (var index = 0; index < mixed.length; index++) {
        mixed[index] ^= block[index];
      }
    }
    output.add(mixed);
  }

  return Uint8List.sublistView(output.toBytes(), 0, length);
}

Uint8List _randomBytes(int length) {
  return Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );
}

List<int> _int32(int value) {
  return [
    (value >> 24) & 0xff,
    (value >> 16) & 0xff,
    (value >> 8) & 0xff,
    value & 0xff,
  ];
}

bool _fixedTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) {
    return false;
  }
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
