import 'dart:convert';

import 'package:convert/convert.dart';

extension StringParsing on String {
  String get utf8Message {
    if (startsWith('0x')) {
      final List<int> decoded = hex.decode(
        substring(2),
      );
      return utf8.decode(decoded);
    }

    return this;
  }
}