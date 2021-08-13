import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

part 'buy_amount_view_model.g.dart';

class BuyAmountViewModel = BuyAmountViewModelBase with _$BuyAmountViewModel;

abstract class BuyAmountViewModelBase with Store {
  BuyAmountViewModelBase({this.settingsStore}) : amount = '';

  final SettingsStore settingsStore;

  @observable
  String amount;

  @computed
  FiatCurrency get fiatCurrency => settingsStore.fiatCurrency;

  FiatCurrency get defaultFiatCurrency => FiatCurrency.usd;

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
}