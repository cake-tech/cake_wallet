class Unspent {
  Unspent(this.address, this.hash, this.value, this.vout, this.keyImage)
      : isSending = true,
        isFrozen = false,
        isChange = false,
        note = '';

  final String address;
  final String hash;
  final int value;
  final int vout;
  final String? keyImage;

  bool isChange;
  bool isSending;
  bool isFrozen;
  String note;

  bool get isP2wpkh => address.startsWith('bc') || address.startsWith('ltc');
}
