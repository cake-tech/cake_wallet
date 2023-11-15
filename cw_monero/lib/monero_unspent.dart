import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_monero/api/structs/coins_info_row.dart';

class MoneroUnspent extends Unspent {
  MoneroUnspent(
      String address, String hash, String keyImage, int value, bool isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage) {
    this.isFrozen = isFrozen;
  }

  factory MoneroUnspent.fromCoinsInfoRow(CoinsInfoRow coinsInfoRow) => MoneroUnspent(
      coinsInfoRow.getAddress(),
      coinsInfoRow.getHash(),
      coinsInfoRow.getKeyImage(),
      coinsInfoRow.amount,
      coinsInfoRow.frozen == 1,
      coinsInfoRow.unlocked == 1);

  final bool isUnlocked;
}
