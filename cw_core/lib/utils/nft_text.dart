// Control characters and bidi overrides let a mint's own metadata fake extra
// lines or reverse the text around it wherever the name is shown.
final _unsafeDisplayCharacters = RegExp(
  "[\u0000-\u001F\u007F\u00AD\u034F\u061C\u115F\u1160\u180E\u200B\u200E\u200F"
  "\u2028\u2029\u202A-\u202E\u2060-\u2064\u2066-\u2069\u3164\uFEFF\uFFA0]"
  "|[\u{E0000}-\u{E007F}]",
  unicode: true,
);

const _maxDisplayTextLength = 512;

String? sanitizeNFTText(String? text) {
  if (text == null) {
    return null;
  }

  final cleaned = text.replaceAll(_unsafeDisplayCharacters, " ").trim();
  final runes = cleaned.runes;

  if (runes.length <= _maxDisplayTextLength) {
    return cleaned;
  }

  return "${String.fromCharCodes(runes.take(_maxDisplayTextLength))}\u2026";
}
