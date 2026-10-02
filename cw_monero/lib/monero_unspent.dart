import 'package:cw_core/unspent_transaction_output.dart';

class MoneroUnspent extends Unspent {
  MoneroUnspent({
    required String address,
    required String hash,
    required String keyImage,
    required int value,
    required this.isUnlocked,
    required this.isSpent,
  }) : super(address, hash, value, 0, keyImage);

  final bool isUnlocked;
  final bool isSpent;

  Map<String, dynamic> toJson() => {
        'address': address,
        'hash': hash,
        'keyImage': keyImage,
        'value': value,
        'isUnlocked': isUnlocked,
        'isChange': isChange,
        'isSpent': isSpent,
      };
}
