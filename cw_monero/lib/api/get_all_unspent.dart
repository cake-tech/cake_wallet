import 'package:cw_monero/api/account_list.dart';
import 'package:cw_monero/monero_unspent.dart';

Map<String, Map<String, dynamic>> getAllUnspent() {
  final coins = currentWallet!.coins();
  coins.refresh();
  final coinCount = coins.count();

  final ret = <String, Map<String, dynamic>>{};
  ret["_count"] = {coinCount.toString(): coinCount};
  for (var i = 0; i < coinCount; i++) {
    final coin = coins.coin(i);
    final subaddr = coin.subaddrAccount();
    if (ret[subaddr.toString()] == null) {
      ret[subaddr.toString()] = {};
    }

    final unspent = MoneroUnspent.fromUnspent(
      address: coin.address(),
      hash: coin.hash(),
      keyImage: coin.keyImage(),
      value: coin.amount(),
      isFrozen: coin.frozen(),
      isUnlocked: coin.unlocked(),
      isSpent: coin.spent(),
    );
    ret[subaddr.toString()]!["0x${coin.ffiAddress().toRadixString(16)}"] = unspent.toJson();
  }
  return ret;
}
