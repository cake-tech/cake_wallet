import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/monero_amount_format.dart';
import 'package:cake_wallet/salvium/salvium.dart';

Future<void> updateSalviumRate(FiatConversionStore fiatConversionStore) async {
  try {
    final rate = salvium!.getAssetRate();
    final base = rate.firstWhere((row) => row.asset == 'XUSD');

    rate.forEach((row) {
      final cur = CryptoCurrency.fromString(row.asset);
      final baseRate = moneroAmountToDouble(amount: base.rate);
      final rowRate = moneroAmountToDouble(amount: row.rate);

      if (cur == CryptoCurrency.xusd) {
        fiatConversionStore.prices[cur] = 1.0;
        return;
      }

      fiatConversionStore.prices[cur] = baseRate / rowRate;
    });
  } catch(_) {
    // FIX-ME: handle exception    
  }
}