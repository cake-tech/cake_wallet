
class Unspent {
  Unspent(this.address, this.hash, this.value, this.vout, this.keyImage) : isChange = false;

  final String address;
  final String hash;
  final int value;
  final int vout;
  final String? keyImage;

  bool isChange;
  int? confirmations;

  String get id => keyImage ?? "$hash:$vout";

  bool get isSilentPayment => false;

  bool get isP2wpkh =>
      address.startsWith("bc") || address.startsWith("tb") || address.startsWith("ltc");

  @override
  String toString() => "Unspent(id: $id, address: $address, value: $value, isChange: $isChange)";
}
