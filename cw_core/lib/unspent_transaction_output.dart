import 'package:cw_core/unspent_comparable_mixin.dart';

class Unspent with UnspentComparable {
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
  int? confirmations;
  String note;

  bool get isP2wpkh =>
      address.startsWith('bc') || address.startsWith('tb') || address.startsWith('ltc');

  @override
  String toString() {
    return 'Unspent(address: $address, hash: $hash, value: $value, vout: $vout, keyImage: $keyImage, isSending: $isSending, isFrozen: $isFrozen, isChange: $isChange, note: $note)';
  }
}
