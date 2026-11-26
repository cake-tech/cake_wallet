class EvmCalldata {
  factory EvmCalldata.fromBody(String hexBody) {
    final normalized = hexBody.toLowerCase();
    final clean = normalized.startsWith("0x") ? normalized.substring(2) : normalized;
    return EvmCalldata._("", clean);
  }
  EvmCalldata._(this.selector, this.body);

  static final uint160Max = (BigInt.one << 160) - BigInt.one;
  static final uint256Max = (BigInt.one << 256) - BigInt.one;

  final String selector;
  final String body;

  static EvmCalldata? parse(String? rawData) {
    if (rawData == null) {
      return null;
    }
    final normalized = rawData.toLowerCase();
    final hex = normalized.startsWith("0x") ? normalized.substring(2) : normalized;
    if (hex.isEmpty) {
      return null;
    }
    final selectorEnd = hex.length < 8 ? hex.length : 8;
    return EvmCalldata._(hex.substring(0, selectorEnd), hex.substring(selectorEnd));
  }

  EvmCalldata? zeroPaddedTo(int words) =>
      body.length < words * 64 ? EvmCalldata._(selector, body.padRight(words * 64, "0")) : null;

  String? wordAt(int index) {
    final start = index * 64;
    if (body.length < start + 64) {
      return null;
    }
    return body.substring(start, start + 64);
  }

  String? addressAt(int index) {
    final word = wordAt(index);
    if (word == null) {
      return null;
    }
    return "0x${word.substring(24, 64)}";
  }

  BigInt? uintAt(int index) {
    final word = wordAt(index);
    if (word == null) {
      return null;
    }
    return BigInt.tryParse(word, radix: 16);
  }

  int? boundedUintAt(int index) {
    final value = uintAt(index);
    if (value == null || value > BigInt.from(body.length ~/ 2)) {
      return null;
    }
    return value.toInt();
  }

  bool? boolAt(int index) {
    final value = uintAt(index);
    if (value == BigInt.zero) {
      return false;
    }
    if (value == BigInt.one) {
      return true;
    }
    return null;
  }

  int? _charOffset(BigInt? byteCount, int availableChars) {
    if (byteCount == null || byteCount < BigInt.zero) {
      return null;
    }
    if (byteCount > BigInt.from(availableChars ~/ 2)) {
      return null;
    }
    return byteCount.toInt() * 2;
  }

  int? _tailStart(int wordIndex) {
    final start = _charOffset(uintAt(wordIndex), body.length);
    if (start == null || body.length < start + 64) {
      return null;
    }
    return start;
  }

  List<int>? dynamicBytesAt(int wordIndex, {int? lengthBits}) {
    final lengthStart = _tailStart(wordIndex);
    if (lengthStart == null) {
      return null;
    }
    final dataStart = lengthStart + 64;
    final lengthWord = BigInt.tryParse(body.substring(lengthStart, dataStart), radix: 16);
    final length = _charOffset(
      lengthBits == null ? lengthWord : lengthWord?.toUnsigned(lengthBits),
      body.length - dataStart,
    );
    if (length == null) {
      return null;
    }
    return [
      for (var byteStart = dataStart; byteStart < dataStart + length; byteStart += 2)
        int.parse(body.substring(byteStart, byteStart + 2), radix: 16),
    ];
  }

  List<String>? addressArrayAt(int wordIndex) =>
      _wordArrayAt(wordIndex)?.map((word) => "0x${word.substring(24)}").toList();

  List<BigInt>? uintArrayAt(int wordIndex) {
    final words = _wordArrayAt(wordIndex);
    if (words == null) {
      return null;
    }
    final values = [for (final word in words) BigInt.tryParse(word, radix: 16)];
    return values.contains(null) ? null : values.nonNulls.toList();
  }

  List<String>? _wordArrayAt(int wordIndex) {
    final lengthStart = _tailStart(wordIndex);
    if (lengthStart == null) {
      return null;
    }
    final firstWord = lengthStart + 64;
    final length = BigInt.tryParse(body.substring(lengthStart, firstWord), radix: 16);
    if (length == null || length < BigInt.zero) {
      return null;
    }
    if (length > BigInt.from((body.length - firstWord) ~/ 64)) {
      return null;
    }
    return [
      for (var start = firstWord; start < firstWord + length.toInt() * 64; start += 64)
        body.substring(start, start + 64),
    ];
  }

  EvmCalldata? structAt(int wordIndex) {
    final start = _tailStart(wordIndex);
    return start == null ? null : EvmCalldata.fromBody(body.substring(start));
  }

  List<String>? bytesArrayAt(int wordIndex, {int? lengthBits}) {
    final arrStart = _tailStart(wordIndex);
    if (arrStart == null) {
      return null;
    }
    final countWord = BigInt.tryParse(body.substring(arrStart, arrStart + 64), radix: 16);
    final count = (lengthBits == null ? countWord : countWord?.toUnsigned(lengthBits))?.toInt();
    if (count == null || count < 0) {
      return null;
    }

    final headStart = arrStart + 64;
    final out = <String>[];
    int totalLength = 0;
    for (var index = 0; index < count; index++) {
      final offWordStart = headStart + index * 64;
      if (body.length < offWordStart + 64) {
        return null;
      }
      final elemOff = _charOffset(
        BigInt.tryParse(body.substring(offWordStart, offWordStart + 64), radix: 16),
        body.length - headStart,
      );
      if (elemOff == null) {
        return null;
      }
      final elemStart = headStart + elemOff;
      if (body.length < elemStart + 64) {
        return null;
      }
      final elemLen = _charOffset(
        BigInt.tryParse(body.substring(elemStart, elemStart + 64), radix: 16),
        body.length - elemStart - 64,
      );
      if (elemLen == null) {
        return null;
      }
      final dataStart = elemStart + 64;
      final dataEnd = dataStart + elemLen;
      if (body.length < dataEnd) {
        return null;
      }
      totalLength += elemLen;
      if (totalLength > body.length) {
        return null;
      }
      out.add(body.substring(dataStart, dataEnd));
    }
    return out;
  }

  static String addressFromBytes(List<int> bytes, int offset) {
    final slice = bytes.sublist(offset, offset + 20);
    final hex = slice.map((byte) => byte.toRadixString(16).padLeft(2, "0")).join();
    return "0x$hex";
  }
}
