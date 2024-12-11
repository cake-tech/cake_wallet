import 'package:cw_core/unspent_transaction_output.dart';

class SalviumUnspent extends Unspent {
  SalviumUnspent(String address, String hash, String keyImage, int value,
      bool isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage) {}

  final bool isUnlocked;
}
