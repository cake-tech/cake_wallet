import 'dart:convert';
import 'dart:math';

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

  String safeSubString(int start, int end) {
    return this.substring(0, min(this.toString().length, 12));
  }
}
