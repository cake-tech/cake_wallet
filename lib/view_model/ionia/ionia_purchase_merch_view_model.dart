import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';

part 'ionia_purchase_merch_view_model.g.dart';

class IoniaMerchPurchaseViewModel = IoniaMerchPurchaseViewModelBase with _$IoniaMerchPurchaseViewModel;

abstract class IoniaMerchPurchaseViewModelBase with Store {
  IoniaMerchPurchaseViewModelBase({this.ioniaMerchantSource}) {
    tipAmount = 0.0;
    amount = '';
    enableCardPurchase = false;
    if (ioniaMerchantSource.length > 0) {
       ioniaMerchant = ioniaMerchantSource.getAt(0);
    }
  }

  final Box<IoniaMerchant> ioniaMerchantSource;

  IoniaMerchant ioniaMerchant;

  @observable
  String amount;

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
    final min =  ioniaMerchant.minimumCardPurchase;
    final max = ioniaMerchant.maximumCardPurchase;

    enableCardPurchase = inputAmount >= min && inputAmount <= max;
  }

  @action
  void addTip(String tip) {
    tipAmount = double.parse(tip);
  }

}
