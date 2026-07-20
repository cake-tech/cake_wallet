import "package:cake_wallet/di.dart";
import "package:cake_wallet/entities/fiat_currency.dart";
import "package:cake_wallet/store/dashboard/fiat_conversion_store.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";

class SwapAmount {
  SwapAmount({required this.cryptoAmount, required this.fiatAmount});

  final Money cryptoAmount;
  final Money fiatAmount;
}
