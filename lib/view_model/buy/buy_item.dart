import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/buy_provider.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/view_model/buy/buy_amount_view_model.dart';

class BuyItem {
  BuyItem({required this.provider, required this.buyAmountViewModel});

  final BuyProvider provider;
  final BuyAmountViewModel buyAmountViewModel;

  double get amount => buyAmountViewModel.doubleAmount;

  FiatCurrency get fiatCurrency => buyAmountViewModel.fiatCurrency;

  Future<BuyAmount> get buyAmount async {
    BuyAmount _buyAmount;

    try {
      _buyAmount = await provider
          .calculateAmount(amount?.toString() ?? '', fiatCurrency.title);
    } catch (e) {
      _buyAmount = BuyAmount(sourceAmount: 0.0, destAmount: 0.0);
      print(e.toString());
    }

    return _buyAmount;
  }
}