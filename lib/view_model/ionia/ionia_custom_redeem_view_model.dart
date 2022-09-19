import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:mobx/mobx.dart';
part 'ionia_custom_redeem_view_model.g.dart';
class IoniaCustomRedeemViewModel = IoniaCustomRedeemViewModelBase with _$IoniaCustomRedeemViewModel;

abstract class IoniaCustomRedeemViewModelBase with Store {
  IoniaCustomRedeemViewModelBase(this.giftCard){
    amount = 0;
  }

  final IoniaGiftCard giftCard;

  @observable
  double amount;

  @computed
  double get remaining =>  amount <= giftCard.remainingAmount ? giftCard.remainingAmount  - amount : 0;

  @computed
  String get formattedRemaining =>  remaining.toStringAsFixed(2);

  @computed
  bool get disableRedeem => amount > giftCard.remainingAmount;

  @action
  void updateAmount(String text){
      amount = text.isEmpty ? 0 : (double.parse(text.replaceAll(',', '.')) ?? 0);
  }

}