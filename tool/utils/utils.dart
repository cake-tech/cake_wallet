import 'package:intl/intl.dart';

String normalizeKeyName(String key) {
  final parts = key.split('_');
  final firstWord = parts.removeAt(0);
  final capitalized = parts
      .map((e) => toBeginningOfSentenceCase(e))
      .fold('', (String acc, String? word) => acc + (word ?? ''));
  return firstWord + capitalized;
}

String generateConst(String name, Map<String, dynamic> config) =>
    'const $name = \'${config["$name"]}\';\n';
