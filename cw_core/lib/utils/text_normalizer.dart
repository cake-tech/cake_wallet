import 'package:unorm_dart/unorm_dart.dart' as unorm;

const CJKINTERVALS = [
  [0x4e00, 0x9fff, 'CJK Unified Ideographs'],
  [0x3400, 0x4dbf, 'CJK Unified Ideographs Extension A'],
  [0x20000, 0x2a6df, 'CJK Unified Ideographs Extension B'],
  [0x2a700, 0x2b73f, 'CJK Unified Ideographs Extension C'],
  [0x2b740, 0x2b81f, 'CJK Unified Ideographs Extension D'],
  [0xf900, 0xfaff, 'CJK Compatibility Ideographs'],
  [0x2f800, 0x2fa1d, 'CJK Compatibility Ideographs Supplement'],
  [0x3190, 0x319f, 'Kanbun'],
  [0x2e80, 0x2eff, 'CJK Radicals Supplement'],
  [0x2f00, 0x2fdf, 'CJK Radicals'],
  [0x31c0, 0x31ef, 'CJK Strokes'],
  [0x2ff0, 0x2fff, 'Ideographic Description Characters'],
  [0xe0100, 0xe01ef, 'Variation Selectors Supplement'],
  [0x3100, 0x312f, 'Bopomofo'],
  [0x31a0, 0x31bf, 'Bopomofo Extended'],
  [0xff00, 0xffef, 'Halfwidth and Fullwidth Forms'],
  [0x3040, 0x309f, 'Hiragana'],
  [0x30a0, 0x30ff, 'Katakana'],
  [0x31f0, 0x31ff, 'Katakana Phonetic Extensions'],
  [0x1b000, 0x1b0ff, 'Kana Supplement'],
  [0xac00, 0xd7af, 'Hangul Syllables'],
  [0x1100, 0x11ff, 'Hangul Jamo'],
  [0xa960, 0xa97f, 'Hangul Jamo Extended A'],
  [0xd7b0, 0xd7ff, 'Hangul Jamo Extended B'],
  [0x3130, 0x318f, 'Hangul Compatibility Jamo'],
  [0xa4d0, 0xa4ff, 'Lisu'],
  [0x16f00, 0x16f9f, 'Miao'],
  [0xa000, 0xa48f, 'Yi Syllables'],
  [0xa490, 0xa4cf, 'Yi Radicals'],
];

final COMBININGCODEPOINTS = combiningcodepoints();

List<int> combiningcodepoints() {
  final source = '300:34e|350:36f|483:487|591:5bd|5bf|5c1|5c2|5c4|5c5|5c7|610:61a|64b:65f|670|' +
      '6d6:6dc|6df:6e4|6e7|6e8|6ea:6ed|711|730:74a|7eb:7f3|816:819|81b:823|825:827|' +
      '829:82d|859:85b|8d4:8e1|8e3:8ff|93c|94d|951:954|9bc|9cd|a3c|a4d|abc|acd|b3c|' +
      'b4d|bcd|c4d|c55|c56|cbc|ccd|d4d|dca|e38:e3a|e48:e4b|eb8|eb9|ec8:ecb|f18|f19|' +
      'f35|f37|f39|f71|f72|f74|f7a:f7d|f80|f82:f84|f86|f87|fc6|1037|1039|103a|108d|' +
      '135d:135f|1714|1734|17d2|17dd|18a9|1939:193b|1a17|1a18|1a60|1a75:1a7c|1a7f|' +
      '1ab0:1abd|1b34|1b44|1b6b:1b73|1baa|1bab|1be6|1bf2|1bf3|1c37|1cd0:1cd2|' +
      '1cd4:1ce0|1ce2:1ce8|1ced|1cf4|1cf8|1cf9|1dc0:1df5|1dfb:1dff|20d0:20dc|20e1|' +
      '20e5:20f0|2cef:2cf1|2d7f|2de0:2dff|302a:302f|3099|309a|a66f|a674:a67d|a69e|' +
      'a69f|a6f0|a6f1|a806|a8c4|a8e0:a8f1|a92b:a92d|a953|a9b3|a9c0|aab0|aab2:aab4|' +
      'aab7|aab8|aabe|aabf|aac1|aaf6|abed|fb1e|fe20:fe2f|101fd|102e0|10376:1037a|' +
      '10a0d|10a0f|10a38:10a3a|10a3f|10ae5|10ae6|11046|1107f|110b9|110ba|11100:11102|' +
      '11133|11134|11173|111c0|111ca|11235|11236|112e9|112ea|1133c|1134d|11366:1136c|' +
      '11370:11374|11442|11446|114c2|114c3|115bf|115c0|1163f|116b6|116b7|1172b|11c3f|' +
      '16af0:16af4|16b30:16b36|1bc9e|1d165:1d169|1d16d:1d172|1d17b:1d182|1d185:1d18b|' +
      '1d1aa:1d1ad|1d242:1d244|1e000:1e006|1e008:1e018|1e01b:1e021|1e023|1e024|' +
      '1e026:1e02a|1e8d0:1e8d6|1e944:1e94a';

  return source.split('|').map((e) {
    if (e.contains(':')) {
      return e.split(':').map((hex) => int.parse(hex, radix: 16));
    }

    return int.parse(e, radix: 16);
  }).fold(<int>[], (List<int> acc, element) {
    if (element is List) {
      for (var i = element[0] as int; i <= (element[1] as int); i++) {}
    } else if (element is int) {
      acc.add(element);
    }

    return acc;
  }).toList();
}

String _removeCombiningCharacters(String source) {
  return source
      .split('')
      .where((char) => !COMBININGCODEPOINTS.contains(char.codeUnits.first))
      .join('');
}

String _removeCJKSpaces(String source) {
  final splitted = source.split('');
  final filtered = <String>[];

  for (var i = 0; i < splitted.length; i++) {
    final char = splitted[i];
    final isSpace = char.trim() == '';
    final prevIsCJK = i != 0 && _isCJK(splitted[i - 1]);
    final nextIsCJK = i != splitted.length - 1 && _isCJK(splitted[i + 1]);

    if (!(isSpace && prevIsCJK && nextIsCJK)) {
      filtered.add(char);
    }
  }

  return filtered.join('');
}

bool _isCJK(String char) {
  final n = char.codeUnitAt(0);

  for (var x in CJKINTERVALS) {
    final imin = x[0] as num;
    final imax = x[1] as num;

    if (n >= imin && n <= imax) return true;
  }

  return false;
}

/// This method normalize text which transforms Unicode text into an equivalent decomposed form, allowing for easier sorting and searching of text.
String normalizeText(String source) {
  final res =
      _removeCombiningCharacters(unorm.nfkd(source).toLowerCase()).trim().split('/\s+/').join(' ');

  return _removeCJKSpaces(res);
}
