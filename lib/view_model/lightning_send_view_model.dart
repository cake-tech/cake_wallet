import 'dart:async';
import 'package:breez_sdk/breez_sdk.dart';
import 'package:breez_sdk/bridge_generated.dart' as BZG;
import 'package:cake_wallet/entities/calculate_fiat_amount_raw.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/lightning/lightning.dart';
import 'package:cake_wallet/store/dashboard/fiat_conversion_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';

part 'lightning_send_view_model.g.dart';

class LightningSendViewModel = LightningSendViewModelBase with _$LightningSendViewModel;

abstract class LightningSendViewModelBase with Store {
  LightningSendViewModelBase({
    required this.settingsStore,
    required this.fiatConversionStore,
  }) {}

  final SettingsStore settingsStore;
  final FiatConversionStore fiatConversionStore;
  
  @observable
  bool loading = false;

  @action
  void setLoading(bool value) {
    loading = value;
  }

  FiatCurrency get fiat => settingsStore.fiatCurrency;

  String formattedFiatAmount(int sats) {
    String amount = calculateFiatAmountRaw(
      cryptoAmount: lightning!.formatterLightningAmountToDouble(amount: sats),
      price: fiatConversionStore.prices[CryptoCurrency.btcln],
    );
    return amount;
  }

}
