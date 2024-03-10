import 'package:cw_core/amount_converter.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_amount_format.dart';

class ZanoBalance extends Balance {
  final int total;
  final int unlocked;
  ZanoBalance({required this.total, required this.unlocked}): super(unlocked, total-unlocked);

  @override
  String get formattedAdditionalBalance => AmountConverter.amountIntToString(CryptoCurrency.zano, total-unlocked);

  @override
  String get formattedAvailableBalance => AmountConverter.amountIntToString(CryptoCurrency.zano, unlocked);

  @override
  String get formattedFrozenBalance => '';

}
