import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:mobx/mobx.dart';

part 'ionia_gift_card_details_view_model.g.dart';

class IoniaGiftCardDetailsViewModel  = IoniaGiftCardDetailsViewModelBase with _$IoniaGiftCardDetailsViewModel;

abstract class IoniaGiftCardDetailsViewModelBase with Store {

  IoniaGiftCardDetailsViewModelBase({this.ioniaService, this.giftCard}) {
    redeemState = InitialExecutionState();
  }

  final IoniaService ioniaService;
  
  @observable
  IoniaGiftCard giftCard;

  @observable
  ExecutionState redeemState;

  @action
  Future<void> redeem() async {
    try {
      redeemState = IsExecutingState();
      await ioniaService.redeem(giftCard);
      giftCard = await ioniaService.getGiftCard(id: giftCard.id);
      redeemState = ExecutedSuccessfullyState();
    } catch(e) {
      redeemState = FailureState(e.toString());
    }
  }
}