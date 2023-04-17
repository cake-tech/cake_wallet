import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';
part 'ionia_custom_redeem_view_model.g.dart';

class IoniaCustomRedeemViewModel = IoniaCustomRedeemViewModelBase with _$IoniaCustomRedeemViewModel;

abstract class IoniaCustomRedeemViewModelBase with Store {
  IoniaCustomRedeemViewModelBase({
    required this.giftCard,
    required this.ioniaService,
  })  : amount = 0,
        redeemState = InitialExecutionState();

  final IoniaGiftCard giftCard;

  final IoniaService ioniaService;

  @observable
  ExecutionState redeemState;

  @observable
  double amount;

  @computed
  double get remaining =>
      amount <= giftCard.remainingAmount ? giftCard.remainingAmount - amount : 0;

  @computed
  String get formattedRemaining => remaining.toStringAsFixed(2);

  @computed
  bool get disableRedeem => amount > giftCard.remainingAmount;

  @action
  void updateAmount(String text) {
    amount = double.tryParse(text.replaceAll(',', '.')) ?? 0;
  }

  @action
  Future<void> addCustomRedeem() async {
    try {
      redeemState = IsExecutingState();
      await ioniaService.redeem(giftCardId: giftCard.id, amount: amount);
      redeemState = ExecutedSuccessfullyState();
    } catch (e) {
      redeemState = FailureState(e.toString());
    }
  }
}
