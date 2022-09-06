import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:mobx/mobx.dart';
import 'package:device_display_brightness/device_display_brightness.dart';

part 'ionia_gift_card_details_view_model.g.dart';

class IoniaGiftCardDetailsViewModel  = IoniaGiftCardDetailsViewModelBase with _$IoniaGiftCardDetailsViewModel;

abstract class IoniaGiftCardDetailsViewModelBase with Store {

  IoniaGiftCardDetailsViewModelBase({this.ioniaService, this.giftCard}) {
    redeemState = InitialExecutionState();
    remainingAmount = giftCard.remainingAmount;
  }

  final IoniaService ioniaService;
  double brightness;
  
  @observable
  IoniaGiftCard giftCard;

  @observable
  double remainingAmount;

  @observable
  ExecutionState redeemState;

  @action
  Future<void> redeem() async {
    giftCard.remainingAmount = remainingAmount;
    try {
      redeemState = IsExecutingState();
      await ioniaService.redeem(giftCard);
      giftCard = await ioniaService.getGiftCard(id: giftCard.id);
      redeemState = ExecutedSuccessfullyState();
    } catch(e) {
      redeemState = FailureState(e.toString());
    }
  }

  @action
  void updateRemaining(double amount){
    remainingAmount = amount;
  }

  void increaseBrightness() async {
    brightness = await DeviceDisplayBrightness.getBrightness();
    await DeviceDisplayBrightness.setBrightness(1.0);
  }
}