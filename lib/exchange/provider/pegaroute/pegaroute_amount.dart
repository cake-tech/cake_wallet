/// Compare human decimal quantities exactly, without changing the retained
/// request or execution bytes. Exponents, signs and rounding are not accepted.
bool pegarouteSameAmount(String first, String second) {
  String? canonical(String value) {
    final text = value.trim();
    if (!RegExp(r'^(0|[1-9][0-9]*)(\.[0-9]+)?$').hasMatch(text)) return null;
    final parts = text.split('.');
    final fraction = parts.length == 1 ? '' : parts[1].replaceFirst(RegExp(r'0+$'), '');
    return fraction.isEmpty ? parts[0] : '${parts[0]}.$fraction';
  }

  final a = canonical(first);
  return a != null && a == canonical(second);
}
