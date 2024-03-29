import 'package:cake_wallet/ionia/cake_pay_vendor.dart';
import 'package:mobx/mobx.dart';

part 'ionia_buy_card_view_model.g.dart';

class CakePayBuyCardViewModel = CakePayBuyCardViewModelBase with _$CakePayBuyCardViewModel;

abstract class CakePayBuyCardViewModelBase with Store {
  CakePayBuyCardViewModelBase({required this.vendor})
    : isEnablePurchase = false,
      amount = 0;

  final CakePayVendor vendor;

  @observable
  double amount;

  @observable
  bool isEnablePurchase;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input.replaceAll(',', '.'));
    final min = 1; //ioniaMerchant.minimumCardPurchase; TODO: uncomment this line
    final max = 10 ;//ioniaMerchant.maximumCardPurchase;

    isEnablePurchase = amount >= min && amount <= max;
  }
}
