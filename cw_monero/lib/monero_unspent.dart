import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/coins_info.dart';
import 'package:monero/monero.dart' as monero;

class MoneroUnspent extends Unspent {
  MoneroUnspent(
      String address, String hash, String keyImage, int value, bool isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage) {
    printV("get isFrozen");
    getCoinByKeyImage(keyImage).then((coinId) {
      if (coinId == null) throw Exception("Unable to find a coin for address $address");
      getCoin(coinId).then((coin) {
        _frozen = monero.CoinsInfo_frozen(coin);
      });
    });
  }

  bool _frozen = false;

  @override
  set isFrozen(bool freeze) {
    printV("set isFrozen: $freeze ($keyImage): $freeze");
    getCoinByKeyImage(keyImage!).then((coinId) {
      if (coinId == null) throw Exception("Unable to find a coin for address $address");
      if (freeze) {
        freezeCoin(coinId);
        _frozen = true;
      } else {
        thawCoin(coinId);
        _frozen = false;
      }
    });
  }

  final bool isUnlocked;
}
