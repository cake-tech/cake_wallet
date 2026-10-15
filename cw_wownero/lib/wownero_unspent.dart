import 'package:cw_core/unspent_transaction_output.dart';

class WowneroUnspent extends Unspent {
  WowneroUnspent(
      String address, String hash, String keyImage, int value, this.isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage);

  final bool isFrozen;
  final bool isUnlocked;
}
