import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:mobx/mobx.dart';

part 'ionia_custom_redeem_view_model.g.dart';

class IoniaCustomRedeemViewModel  = IoniaCustomRedeemViewModelBase with _$IoniaCustomRedeemViewModel;

abstract class IoniaCustomRedeemViewModelBase with Store {

  IoniaCustomRedeemViewModelBase({this.giftCard}){
  isAmountAboveRemaining = false;
  amount = 0;
  }
  
 
  @observable
  IoniaGiftCard giftCard;

  @observable
  double amount;

  @computed 
  double get remaining =>  giftCard.remainingAmount - amount;

  @observable
  bool isAmountAboveRemaining;

  @action
  Future<void> onAmountChanged(String value) async {
    if(value.isEmpty) return;
    final parsedAmount = double.parse(value);
    isAmountAboveRemaining = giftCard.remainingAmount < parsedAmount;
    amount = isAmountAboveRemaining ? 0 : parsedAmount;

  }
}