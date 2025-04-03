import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/coins_info.dart';
import 'package:monero/monero.dart' as monero;

class MoneroUnspent extends Unspent {
  MoneroUnspent(
      String address, String hash, String keyImage, int value, bool isFrozen, this.isUnlocked)
      : super(address, hash, value, 0, keyImage) {
    getCoinByKeyImage(keyImage).then((coinId) {
      if (coinId == null) return;
      getCoin(coinId).then((coin) {
        _frozen = monero.CoinsInfo_frozen(coin);
      });
    });
  }

  bool _frozen = false;

  @override
  set isFrozen(bool freeze) {
    printV("set isFrozen: $freeze ($keyImage): $freeze");
    getCoinByKeyImage(keyImage!).then((coinId) async {
      if (coinId == null) return;
      if (freeze) {
        await freezeCoin(coinId);
        _frozen = true;
      } else {
        await thawCoin(coinId);
        _frozen = false;
      }
    });
  }

  @override
  bool get isFrozen => _frozen;

  final bool isUnlocked;
}
