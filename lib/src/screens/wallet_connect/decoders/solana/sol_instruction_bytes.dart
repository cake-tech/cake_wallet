class SolInstructionBytes {
  SolInstructionBytes(this.bytes);

  final List<int> bytes;

  int? u8(int offset) {
    if (offset + 1 > bytes.length) {
      return null;
    }
    return bytes[offset];
  }

  int? u32Le(int offset) {
    if (offset + 4 > bytes.length) {
      return null;
    }
    return bytes[offset] |
        (bytes[offset + 1] << 8) |
        (bytes[offset + 2] << 16) |
        (bytes[offset + 3] << 24);
  }

  BigInt? u64Le(int offset) {
    if (offset + 8 > bytes.length) {
      return null;
    }
    var value = BigInt.zero;
    for (var i = 7; i >= 0; i--) {
      value = (value << 8) | BigInt.from(bytes[offset + i]);
    }
    return value;
  }
}
