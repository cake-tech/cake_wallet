import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_monero/api/coins_info.dart';
import 'package:monero/monero.dart' as monero;

class MoneroUnspent extends Unspent {
  MoneroUnspent(
      String address, String hash, String keyImage, int value, bool isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage) {
  }

  @override
  set isFrozen(bool freeze) {
    print("set isFrozen: $freeze ($keyImage): $freeze");
    final coinId = getCoinByKeyImage(keyImage!);
    if (coinId == null) throw Exception("Unable to find a coin for address $address");
    if (freeze) {
      freezeCoin(coinId);
    } else {
      thawCoin(coinId);
    }
  }

  @override
  bool get isFrozen {
    print("get isFrozen");
    final coinId = getCoinByKeyImage(keyImage!);
    if (coinId == null) throw Exception("Unable to find a coin for address $address");
    final coin = getCoin(coinId);
    return monero.CoinsInfo_frozen(coin);
  }

  final bool isUnlocked;
}
