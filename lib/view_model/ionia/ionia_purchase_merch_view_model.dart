import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:mobx/mobx.dart';

part 'ionia_purchase_merch_view_model.g.dart';

class IoniaMerchPurchaseViewModel = IoniaMerchPurchaseViewModelBase with _$IoniaMerchPurchaseViewModel;

abstract class IoniaMerchPurchaseViewModelBase with Store {
  IoniaMerchPurchaseViewModelBase() {
    tipAmount = 0.0;
    percentage = 0.0;
    amount = '';
    enableCardPurchase = false;
  }

  IoniaMerchant ioniaMerchant;

  @observable
  String amount;

  @observable
  double percentage;

  @computed
  double get giftCardAmount => double.parse(amount) + tipAmount;

  @observable
  double tipAmount;

  @observable
  bool enableCardPurchase;

  @action
  void onAmountChanged(String input) {
    if (input.isEmpty) return;
    amount = input;
    final inputAmount = double.parse(input);
    final min = ioniaMerchant.minimumCardPurchase;
    final max = ioniaMerchant.maximumCardPurchase;

    enableCardPurchase = inputAmount >= min && inputAmount <= max;
  }

  void onTipChanged(String input) {
    if (input.isEmpty) {
      percentage = 0.00;
      return;
    }
    final tip = double.parse(input);
    final billAmount = double.parse(amount);
    percentage = (tip / billAmount) * 100;
  }

  void setSelectedMerchant(IoniaMerchant merchant) {
    ioniaMerchant = merchant;
  }

  @action
  void addTip(String tip) {
    tipAmount = double.parse(tip);
  }
}
