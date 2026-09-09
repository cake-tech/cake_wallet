class EvmCalldata {
  factory EvmCalldata.fromBody(String hexBody) {
    final normalized = hexBody.toLowerCase();
    final clean = normalized.startsWith("0x") ? normalized.substring(2) : normalized;
    return EvmCalldata._("", clean);
  }
  EvmCalldata._(this.selector, this.body);

  final String selector;
  final String body;

  static EvmCalldata? parse(String? rawData) {
    if (rawData == null) {
      return null;
    }
    final normalized = rawData.toLowerCase();
    final hex = normalized.startsWith("0x") ? normalized.substring(2) : normalized;
    if (hex.length < 8) {
      return null;
    }
    final selector = hex.substring(0, 8);
    final body = hex.length > 8 ? hex.substring(8) : "";
    return EvmCalldata._(selector, body);
  }

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
    final prefix = word.substring(0, 24);
    if (prefix.replaceAll("0", "").isNotEmpty) {
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

  List<int>? dynamicBytesAt(int wordIndex) {
    final byteStart = _charOffset(uintAt(wordIndex), body.length);
    if (byteStart == null) {
      return null;
    }
    if (body.length < byteStart + 64) {
      return null;
    }
    final length = _charOffset(
      BigInt.tryParse(body.substring(byteStart, byteStart + 64), radix: 16),
      body.length - byteStart - 64,
    );
    if (length == null) {
      return null;
    }
    final dataStart = byteStart + 64;
    final dataEnd = dataStart + length;
    if (body.length < dataEnd) {
      return null;
    }
    final out = <int>[];
    for (var i = dataStart; i < dataEnd; i += 2) {
      out.add(int.parse(body.substring(i, i + 2), radix: 16));
    }
    return out;
  }

  List<String>? addressArrayAt(int wordIndex) {
    final byteStart = _charOffset(uintAt(wordIndex), body.length);
    if (byteStart == null) {
      return null;
    }
    if (body.length < byteStart + 64) {
      return null;
    }
    final length = BigInt.tryParse(
      body.substring(byteStart, byteStart + 64),
      radix: 16,
    )?.toInt();
    if (length == null || length < 0) {
      return null;
    }
    final out = <String>[];
    var cursor = byteStart + 64;
    for (var i = 0; i < length; i++) {
      if (body.length < cursor + 64) {
        return null;
      }
      final word = body.substring(cursor, cursor + 64);
      final prefix = word.substring(0, 24);
      if (prefix.replaceAll("0", "").isNotEmpty) {
        return null;
      }
      out.add("0x${word.substring(24, 64)}");
      cursor += 64;
    }
    return out;
  }

  List<BigInt>? uintArrayAt(int wordIndex) {
    final byteStart = _charOffset(uintAt(wordIndex), body.length);
    if (byteStart == null) {
      return null;
    }
    if (body.length < byteStart + 64) {
      return null;
    }
    final length = BigInt.tryParse(
      body.substring(byteStart, byteStart + 64),
      radix: 16,
    )?.toInt();
    if (length == null || length < 0) {
      return null;
    }
    final out = <BigInt>[];
    var cursor = byteStart + 64;
    for (var i = 0; i < length; i++) {
      if (body.length < cursor + 64) {
        return null;
      }
      final value = BigInt.tryParse(body.substring(cursor, cursor + 64), radix: 16);
      if (value == null) {
        return null;
      }
      out.add(value);
      cursor += 64;
    }
    return out;
  }

  EvmCalldata? structAt(int wordIndex) {
    final start = _charOffset(uintAt(wordIndex), body.length);
    if (start == null) {
      return null;
    }
    if (body.length < start + 64) {
      return null;
    }
    return EvmCalldata.fromBody(body.substring(start));
  }

  List<String>? bytesArrayAt(int wordIndex) {
    final arrStart = _charOffset(uintAt(wordIndex), body.length);
    if (arrStart == null) {
      return null;
    }
    if (body.length < arrStart + 64) {
      return null;
    }
    final count = BigInt.tryParse(body.substring(arrStart, arrStart + 64), radix: 16)?.toInt();
    if (count == null || count < 0) {
      return null;
    }

    final headStart = arrStart + 64;
    final out = <String>[];
    for (var i = 0; i < count; i++) {
      final offWordStart = headStart + i * 64;
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
      out.add(body.substring(dataStart, dataEnd));
    }
    return out;
  }
}
