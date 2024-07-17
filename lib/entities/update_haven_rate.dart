import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cake_wallet/haven/haven.dart';

Future<void> updateHavenRate(FiatConversionStore fiatConversionStore) async {
  try {
    final rate = haven!.getAssetRate();

    rate.forEach((row) {
      final cur = CryptoCurrency.fromString(row.asset);
      final rowRate = moneroAmountToDouble(amount: row.rate);
      fiatConversionStore.prices[cur] = rowRate;
    });
  } catch(_) {
    // FIX-ME: handle exception    
  }
}
