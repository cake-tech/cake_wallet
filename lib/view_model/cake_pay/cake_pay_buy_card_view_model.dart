import 'package:cake_wallet/cake_pay/cake_pay_card.dart';
import 'package:cake_wallet/cake_pay/cake_pay_vendor.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_buy_card_view_model.g.dart';

class CakePayBuyCardViewModel = CakePayBuyCardViewModelBase with _$CakePayBuyCardViewModel;

abstract class CakePayBuyCardViewModelBase with Store {
  CakePayBuyCardViewModelBase({required this.vendor})
      : amount = vendor.card!.denominations.isNotEmpty
            ? double.parse(vendor.card!.denominations.first)
            : 0,
        quantity = 1,
        min = double.parse(vendor.card!.minValue ?? '0'),
        max = double.parse(vendor.card!.maxValue ?? '0'),
        card = vendor.card!;

  final CakePayVendor vendor;
  final CakePayCard card;

  final double min;
  final double max;

  bool get isDenominationSelected => card.denominations.isNotEmpty;

  @observable
  double amount;

  @observable
  int quantity;

  @computed
  bool get isEnablePurchase =>
      (amount >= min && amount <= max) || (isDenominationSelected && quantity > 0);

  @computed
  double get totalAmount => amount * quantity;

  @action
  void onQuantityChanged(int? input) => quantity = input ?? 1;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input.replaceAll(',', '.'));
  }
}
