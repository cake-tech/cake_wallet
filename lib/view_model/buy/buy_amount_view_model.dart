import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';

part 'buy_amount_view_model.g.dart';

class BuyAmountViewModel = BuyAmountViewModelBase with _$BuyAmountViewModel;

abstract class BuyAmountViewModelBase with Store {
  BuyAmountViewModelBase()
    : amount = '' {
    int selectedIndex = FiatCurrency.currenciesAvailableToBuyWith
        .indexOf(getIt.get<SettingsStore>().fiatCurrency);

    if (selectedIndex == -1) {
      selectedIndex = FiatCurrency.currenciesAvailableToBuyWith
          .indexOf(FiatCurrency.usd);
    }
    fiatCurrency = FiatCurrency.currenciesAvailableToBuyWith[selectedIndex];
  }

  @observable
  String amount;

  @observable
  late FiatCurrency fiatCurrency;

  @computed
  double get doubleAmount {
    double _amount;

    try {
      _amount = double.parse(amount.replaceAll(',', '.'));
    } catch (_) {
      _amount = 0.0;
    }

    return _amount;
  }
}
