import 'dart:math';

extension StringParsing on String {
  String safeSubString(int start, int end) {
    return this.substring(0, min(this.toString().length, 12));
  }
}
