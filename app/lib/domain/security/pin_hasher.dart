import 'dart:convert';

import 'package:crypto/crypto.dart';

class PinHasher {
  PinHasher._();

  static final pinPattern = RegExp(r'^\d{4}$');

  static bool isValid(String pin) => pinPattern.hasMatch(pin);

  static String hash(String pin, String salt) {
    return sha256.convert(utf8.encode('$salt|$pin')).toString();
  }
}
