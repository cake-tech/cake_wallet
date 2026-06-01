class EvmCalldata {
  EvmCalldata._(this.selector, this.body);

  final String selector;
  final String body;

  static EvmCalldata? parse(String? rawData) {
    if (rawData == null) return null;
    final hex =
        rawData.toLowerCase().startsWith('0x') ? rawData.substring(2) : rawData.toLowerCase();
    if (hex.length < 8) return null;
    final selector = hex.substring(0, 8);
    final body = hex.length > 8 ? hex.substring(8) : '';
    return EvmCalldata._(selector, body);
  }

  int get wordCount => body.length ~/ 64;

  String? wordAt(int index) {
    final start = index * 64;
    if (body.length < start + 64) return null;
    return body.substring(start, start + 64);
  }

  String? addressAt(int index) {
    final word = wordAt(index);
    if (word == null) return null;
    final prefix = word.substring(0, 24);
    if (prefix.replaceAll('0', '').isNotEmpty) return null;
    return '0x${word.substring(24, 64)}';
  }

  BigInt? uintAt(int index) {
    final word = wordAt(index);
    if (word == null) return null;
    return BigInt.tryParse(word, radix: 16);
  }

  bool? boolAt(int index) {
    final word = wordAt(index);
    if (word == null) return null;
    final cleaned = word.replaceAll('0', '');
    if (cleaned.isEmpty) return false;
    if (cleaned == '1') return true;
    return null;
  }

  /// Returns the dynamic bytes/string located behind the offset stored at [wordIndex].
  List<int>? dynamicBytesAt(int wordIndex) {
    final offset = uintAt(wordIndex)?.toInt();
    if (offset == null) return null;
    final byteStart = offset * 2;
    if (body.length < byteStart + 64) return null;
    final length = BigInt.tryParse(
      body.substring(byteStart, byteStart + 64),
      radix: 16,
    )?.toInt();
    if (length == null) return null;
    final dataStart = byteStart + 64;
    final dataEnd = dataStart + length * 2;
    if (body.length < dataEnd) return null;
    final out = <int>[];
    for (var i = dataStart; i < dataEnd; i += 2) {
      out.add(int.parse(body.substring(i, i + 2), radix: 16));
    }
    return out;
  }

  /// Returns a list of addresses stored as `address[]` behind the offset at [wordIndex].
  List<String>? addressArrayAt(int wordIndex) {
    final offset = uintAt(wordIndex)?.toInt();
    if (offset == null) return null;
    final byteStart = offset * 2;
    if (body.length < byteStart + 64) return null;
    final length = BigInt.tryParse(
      body.substring(byteStart, byteStart + 64),
      radix: 16,
    )?.toInt();
    if (length == null) return null;
    final out = <String>[];
    var cursor = byteStart + 64;
    for (var i = 0; i < length; i++) {
      if (body.length < cursor + 64) return null;
      final word = body.substring(cursor, cursor + 64);
      final prefix = word.substring(0, 24);
      if (prefix.replaceAll('0', '').isNotEmpty) return null;
      out.add('0x${word.substring(24, 64)}');
      cursor += 64;
    }
    return out;
  }

  bool isUnlimited(BigInt value) {
    return value >= BigInt.from(2).pow(200);
  }
}
