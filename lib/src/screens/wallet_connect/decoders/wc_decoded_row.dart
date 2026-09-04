enum WCDecodedRowKind {
  text,
  amount,
  address,
}

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
