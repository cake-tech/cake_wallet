import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/coins_info.dart';
import 'package:monero/src/monero.dart';

class MoneroUnspent extends Unspent {
  static Future<MoneroUnspent> fromUnspent(String address, String hash, String keyImage, int value, bool isFrozen, bool isUnlocked) async {
    return MoneroUnspent(
        address: address,
        hash: hash,
        keyImage: keyImage,
        value: value,
        isFrozen: isFrozen,
        isUnlocked: isUnlocked);
  }

  MoneroUnspent(
      {required String address,
      required String hash,
      required String keyImage,
      required int value,
      required bool isFrozen,
      required this.isUnlocked})
      : super(address, hash, value, 0, keyImage) {
    _frozen = isFrozen;
  }

  bool _frozen = false;

  @override
  set isFrozen(bool freeze) {
    _frozen = freeze;
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
