import "package:on_chain/solana/solana.dart";

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
    for (var byteIndex = 7; byteIndex >= 0; byteIndex--) {
      value = (value << 8) | BigInt.from(bytes[offset + byteIndex]);
    }
    return value;
  }

  String? address(int offset) {
    if (offset + 32 > bytes.length) {
      return null;
    }
    return SolAddress.uncheckBytes(bytes.sublist(offset, offset + 32)).address;
  }
}
