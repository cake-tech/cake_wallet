import 'dart:math';

extension StringParsing on String {
  String safeSubString(int start, int end) {
    return this.substring(start, min(this.toString().length, end));
  }
}
