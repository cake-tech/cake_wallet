import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/buy/wyre/wyre_buy_provider.dart';
import 'package:cake_wallet/core/wallet_base.dart';
import 'package:cake_wallet/entities/wallet_type.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

part 'buy_amount_view_model.g.dart';

class BuyAmountViewModel = BuyAmountViewModelBase with _$BuyAmountViewModel;

abstract class BuyAmountViewModelBase with Store {
  BuyAmountViewModelBase({this.settingsStore, this.wallet})
      : amount = '',
        fiatCurrency = settingsStore.fiatCurrency,
        providerList = [
          WyreBuyProvider(wallet: wallet),
          MoonPayBuyProvider(wallet: wallet)] {

    currentProviders = _fetchBuyProviders();
  }

  final SettingsStore settingsStore;
  final WalletBase wallet;
  final List<BuyProvider> providerList;

  @observable
  String amount;

  @observable
  FiatCurrency fiatCurrency;

  Future<List<BuyProvider>> currentProviders;

  @computed
  Future<FiatCurrency> get currentFiatCurrency async {
    for (var provider in providerList) {
      final isFiatSupported =
        await _isProviderSupportFiat(provider, savedFiatCurrency);
      if (!isFiatSupported) {
        return defaultFiatCurrency;
      }
    }

    return savedFiatCurrency;
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

  Future<List<BuyProvider>> _fetchBuyProviders() async {
    final List<BuyProvider> _providerList = [];

    for (var provider in providerList) {
      switch (provider.description) {
        case BuyProviderDescription.wyre:
          if (wallet.type == WalletType.bitcoin) {
            _providerList.add(provider);
          }
          break;
        case BuyProviderDescription.moonPay:
          var isMoonPayEnabled = false;
          try {
            isMoonPayEnabled = await MoonPayBuyProvider.onEnabled();
          } catch (e) {
            isMoonPayEnabled = false;
            print(e.toString());
          }
          if (isMoonPayEnabled) {
            _providerList.add(provider);
          }
          break;
        default:
          break;
      }
    }

    return _providerList;
  }

  Future<bool> _isProviderSupportFiat(BuyProvider provider,
      FiatCurrency currency) async {
    bool result;
    try {
      final testAmount = '1';
      final buyAmount =
        await provider.calculateAmount(testAmount, currency.title);
      result = buyAmount.destAmount > 0 ? true : false;
    } catch (e) {
      print(e.toString);
      result = false;
    }

    return result;
  }
}