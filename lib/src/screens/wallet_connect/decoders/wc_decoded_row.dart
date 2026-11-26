enum WCDecodedRowKind { text, amount, address }

class WCDecodedRow {
  const WCDecodedRow({
    required this.label,
    required this.value,
    this.kind = WCDecodedRowKind.text,
    this.fiatValue,
  });

  final String label;
  final String value;
  final WCDecodedRowKind kind;
  final String? fiatValue;
}

String shortAddress(String address) {
  if (address.length <= 10) {
    return address;
  }
  final prefixLength = address.startsWith("0x") ? 6 : 4;
  return "${address.substring(0, prefixLength)}…${address.substring(address.length - 4)}";
}
