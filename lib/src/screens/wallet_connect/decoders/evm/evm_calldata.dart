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

  /// Wraps an already-stripped ABI args region (no 4-byte selector) so the
  /// word/offset helpers can be reused on it — e.g. a single element of a
  /// Universal Router `bytes[] inputs` array, which is itself `abi.encode(...)`.
  factory EvmCalldata.fromBody(String hexBody) {
    final clean =
        hexBody.toLowerCase().startsWith('0x') ? hexBody.substring(2) : hexBody.toLowerCase();
    return EvmCalldata._('', clean);
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

  /// Decodes a `bytes[]` located behind the offset at [wordIndex], returning
  /// each element's payload as a hex string (the length prefix stripped). Used
  /// for the Universal Router `inputs` array, where every element is itself an
  /// ABI-encoded argument tuple to be re-parsed with [EvmCalldata.fromBody].
  List<String>? bytesArrayAt(int wordIndex) {
    final arrOffset = uintAt(wordIndex)?.toInt();
    if (arrOffset == null) return null;
    final arrStart = arrOffset * 2;
    if (body.length < arrStart + 64) return null;
    final count = BigInt.tryParse(body.substring(arrStart, arrStart + 64), radix: 16)?.toInt();
    if (count == null || count < 0) return null;

    // Element offsets are relative to the start of the area after the count word.
    final headStart = arrStart + 64;
    final out = <String>[];
    for (var i = 0; i < count; i++) {
      final offWordStart = headStart + i * 64;
      if (body.length < offWordStart + 64) return null;
      final elemOff =
          BigInt.tryParse(body.substring(offWordStart, offWordStart + 64), radix: 16)?.toInt();
      if (elemOff == null) return null;
      final elemStart = headStart + elemOff * 2;
      if (body.length < elemStart + 64) return null;
      final elemLen =
          BigInt.tryParse(body.substring(elemStart, elemStart + 64), radix: 16)?.toInt();
      if (elemLen == null) return null;
      final dataStart = elemStart + 64;
      final dataEnd = dataStart + elemLen * 2;
      if (body.length < dataEnd) return null;
      out.add(body.substring(dataStart, dataEnd));
    }
    return out;
  }

  bool isUnlimited(BigInt value) {
    return value >= BigInt.from(2).pow(200);
  }
}
