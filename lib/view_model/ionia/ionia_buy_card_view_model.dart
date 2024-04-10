import 'package:cake_wallet/ionia/cake_pay_card.dart';
import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:mobx/mobx.dart';

part 'ionia_buy_card_view_model.g.dart';

class CakePayBuyCardViewModel = CakePayBuyCardViewModelBase with _$CakePayBuyCardViewModel;

abstract class CakePayBuyCardViewModelBase with Store {
  CakePayBuyCardViewModelBase({required this.vendor})
      : isEnablePurchase = false,
        amount = 0,
        card = vendor.card!;

  final CakePayVendor vendor;

  CakePayCard card;

  @observable
  double amount;

  @observable
  bool isEnablePurchase;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input.replaceAll(',', '.'));
    final min = double.parse(card.minValue ?? '0.0');
    final max = double.parse(card.maxValue ?? '0.0');

    isEnablePurchase = amount >= min && amount <= max;
  }
}
