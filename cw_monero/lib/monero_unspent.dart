import 'package:cw_core/unspent_transaction_output.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_monero/api/coins_info.dart';

class MoneroUnspent extends Unspent {
  static MoneroUnspent fromUnspent({
    required String address,
    required String hash,
    required String keyImage,
    required int value,
    required bool isFrozen,
    required bool isUnlocked,
    required bool isSpent,
  }) {
    return MoneroUnspent(
        address: address,
        hash: hash,
        keyImage: keyImage,
        value: value,
        isFrozen: isFrozen,
        isUnlocked: isUnlocked,
        isSpent: isSpent);
  }

  MoneroUnspent(
      {required String address,
      required String hash,
      required String keyImage,
      required int value,
      required bool isFrozen,
      required this.isUnlocked,
      required this.isSpent})
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
  final bool isSpent;

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'hash': hash,
      'keyImage': keyImage,
      'value': value,
      'isFrozen': isFrozen,
      'isUnlocked': isUnlocked,
      'isChange': isChange,
      'isSpent': isSpent,
    };
  }
}
