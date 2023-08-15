import 'package:cw_monero/api/structs/coins_info_row.dart';

class MoneroUnspent {
  MoneroUnspent(this.address, this.hash, this.keyImage, this.value, this.isFrozen, this.isUnlocked)
      : isSending = true,
        note = '';

  MoneroUnspent.fromCoinsInfoRow(CoinsInfoRow coinsInfoRow)
      : address = coinsInfoRow.getAddress(),
        hash = coinsInfoRow.getHash(),
        keyImage = coinsInfoRow.getKeyImage(),
        value = coinsInfoRow.amount,
        isFrozen = coinsInfoRow.frozen == 1,
        isUnlocked = coinsInfoRow.unlocked == 1,
        isSending = true,
        note = '';

  final String address;
  final String hash;
  final String keyImage;
  final int value;

  final bool isUnlocked;

  bool isFrozen;
  bool isSending;
  String note;
}
