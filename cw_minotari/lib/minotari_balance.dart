import 'package:cw_core/amount/money.dart';
import 'package:cw_core/balance.dart';
import 'package:cw_core/crypto_currency.dart';

/// Amounts are in microTari.
class MinotariBalance extends Balance {
  MinotariBalance({
    required int available,
    required int pendingIncoming,
    required int pendingOutgoing,
  }) : super(
          Money.fromInt(available, CryptoCurrency.xtm),
          Money.fromInt(pendingIncoming + pendingOutgoing, CryptoCurrency.xtm),
        );
}
