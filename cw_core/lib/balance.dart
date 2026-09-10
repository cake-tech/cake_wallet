import 'package:cw_core/amount/money.dart';

/// Balance Data class with all amounts in the lowest possible currency (e.g. satoshis or wei)
abstract class Balance {
  const Balance(
    this.available,
    this.unavailable, {
    this.secondAvailable,
    this.secondUnavailable,
    this.frozen,
  });

  final CryptoMoney available;
  final CryptoMoney unavailable;

  final CryptoMoney? secondAvailable;
  final CryptoMoney? secondUnavailable;

  final CryptoMoney? frozen;
}
