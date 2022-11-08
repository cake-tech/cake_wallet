import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:mobx/mobx.dart';

part 'ionia_buy_card_view_model.g.dart';

class IoniaBuyCardViewModel = IoniaBuyCardViewModelBase with _$IoniaBuyCardViewModel;

abstract class IoniaBuyCardViewModelBase with Store {
  IoniaBuyCardViewModelBase({required this.ioniaMerchant}) 
    : isEnablePurchase = false,
      amount = 0;

  final IoniaMerchant ioniaMerchant;

  @observable
  double amount;

  @observable
  bool isEnablePurchase;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = double.parse(input.replaceAll(',', '.'));
    final min = ioniaMerchant.minimumCardPurchase;
    final max = ioniaMerchant.maximumCardPurchase;

    isEnablePurchase = amount >= min && amount <= max;
  }
}
