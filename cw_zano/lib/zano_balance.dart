import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cw_core/monero_balance.dart';
import 'package:cw_zano/api/balance_list.dart';
import 'package:cw_zano/api/structs/zano_balance_row.dart';

class ZanoBalance extends Balance {
  final int total;
  final int unlocked;
  ZanoBalance({required this.total, required this.unlocked}): super(unlocked, 0);


  @override
  String get formattedAdditionalBalance => moneroAmountToString(amount: additional);

  @override
  String get formattedAvailableBalance => moneroAmountToString(amount: unlocked);

  @override
  String get formattedFrozenBalance => total == unlocked ? '' : moneroAmountToString(amount: total - unlocked);

}
