import 'package:cw_core/unspent_transaction_output.dart';

class MoneroUnspent extends Unspent {
  MoneroUnspent(
      String address, String hash, String keyImage, int value, bool isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage) {
    this.isFrozen = isFrozen;
  }

  final bool isUnlocked;
}
