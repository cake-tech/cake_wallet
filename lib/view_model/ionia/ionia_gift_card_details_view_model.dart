import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:mobx/mobx.dart';
import 'package:device_display_brightness/device_display_brightness.dart';

part 'ionia_gift_card_details_view_model.g.dart';

class IoniaGiftCardDetailsViewModel  = IoniaGiftCardDetailsViewModelBase with _$IoniaGiftCardDetailsViewModel;

abstract class IoniaGiftCardDetailsViewModelBase with Store {

  IoniaGiftCardDetailsViewModelBase({
    required this.ioniaService,
    required this.giftCard}) 
    : redeemState = InitialExecutionState(),
      remainingAmount = giftCard.remainingAmount,
      adjustedAmount = 0,
      brightness = 0;

  final IoniaService ioniaService;
  
  double brightness;
  
  @observable
  IoniaGiftCard giftCard;

  @observable
  double remainingAmount;

  double adjustedAmount;

  @observable
  ExecutionState redeemState;

  @action
  Future<void> redeem() async {
    giftCard.remainingAmount = remainingAmount;
    try {
      redeemState = IsExecutingState();
      await ioniaService.redeem(giftCardId: giftCard.id, amount : adjustedAmount > 0 ? adjustedAmount : giftCard.remainingAmount);
      giftCard = await ioniaService.getGiftCard(id: giftCard.id);
      redeemState = ExecutedSuccessfullyState();
    } catch(e) {
      redeemState = FailureState(e.toString());
    }
  }

  @action
  void updateRemaining({required double balance, required double customAmount}) {
    remainingAmount = balance;
    adjustedAmount = customAmount;
  }

  void increaseBrightness() async {
    brightness = await DeviceDisplayBrightness.getBrightness();
    await DeviceDisplayBrightness.setBrightness(1.0);
  }
}