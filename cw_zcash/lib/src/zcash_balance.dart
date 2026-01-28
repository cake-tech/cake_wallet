import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

class ZcashBalance extends Balance {
  ZcashBalance({required this.confirmed, required this.unconfirmed, required this.frozen})
    : super(confirmed, unconfirmed);

  factory ZcashBalance.zero() => ZcashBalance(confirmed: 0, unconfirmed: 0, frozen: 0);

  final int confirmed;
  final int unconfirmed;
  final int frozen;

  @override
  String get formattedAvailableBalance {
    return CryptoCurrency.zec.formatAmount(BigInt.from(confirmed));
  }

  @override
  String get formattedAdditionalBalance {
    if (unconfirmed == 0) return '0.0';
    return CryptoCurrency.zec.formatAmount(BigInt.from(unconfirmed));
  }

  @override
  String get formattedUnAvailableBalance {
    if (frozen == 0) return '';
    return CryptoCurrency.zec.formatAmount(BigInt.from(frozen));
  }
}
