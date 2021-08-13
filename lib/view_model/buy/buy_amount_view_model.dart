import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

part 'buy_amount_view_model.g.dart';

class BuyAmountViewModel = BuyAmountViewModelBase with _$BuyAmountViewModel;

abstract class BuyAmountViewModelBase with Store {
  BuyAmountViewModelBase({this.settingsStore, this.wallet})
      : amount = '',
        fiatCurrency = settingsStore.fiatCurrency;

  final SettingsStore settingsStore;
  final WalletBase wallet;

  @observable
  String amount;

  @observable
  FiatCurrency fiatCurrency;

  @computed
  Future<FiatCurrency> get currentFiatCurrency async {
    return (await isWyreProviderEnabledForFiat()
        && await isMoonPayProviderEnabledForFiat())
        ? savedFiatCurrency
        : defaultFiatCurrency;
  }

  FiatCurrency get defaultFiatCurrency => FiatCurrency.usd;

  FiatCurrency get savedFiatCurrency => settingsStore.fiatCurrency;

  @computed
  double get doubleAmount {
    double _amount;

    try {
      _amount = double.parse(amount.replaceAll(',', '.')) ?? 0.0;
    } catch (e) {
      _amount = 0.0;
    }

    return _amount;
  }

  Future<bool> isWyreProviderEnabledForFiat() async {
    final wyreProvider = WyreBuyProvider(wallet: wallet);
    return await _isProviderEnabledForFiat(wyreProvider);
  }

  Future<bool> isMoonPayProviderEnabledForFiat() async {
    final moonpayProvider = MoonPayBuyProvider(wallet: wallet);
    return await _isProviderEnabledForFiat(moonpayProvider);
  }

  Future<bool> _isProviderEnabledForFiat(BuyProvider provider) async {
    bool result;
    try {
      final testAmount = '1';
      final buyAmount =
        await provider.calculateAmount(testAmount, savedFiatCurrency.title);
      result = buyAmount.destAmount > 0 ? true : false;
    } catch (e) {
      print(e.toString);
      result = false;
    }
    return result;
  }
}