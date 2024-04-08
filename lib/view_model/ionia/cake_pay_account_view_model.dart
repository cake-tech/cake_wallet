import 'package:cake_wallet/ionia/cake_pay_states.dart';
import 'package:cake_wallet/ionia/cake_pay_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';

part 'cake_pay_account_view_model.g.dart';

class CakePayAccountViewModel = CakePayAccountViewModelBase with _$CakePayAccountViewModel;

abstract class CakePayAccountViewModelBase with Store {
  CakePayAccountViewModelBase({required this.cakePayService})
      : email = '',
        giftCards = [],
        merchantState = InitialCakePayVendorLoadingState() {
    cakePayService.getUserEmail().then((email) => this.email = email);
    updateUserGiftCards();
  }

  final CakePayService cakePayService;

  @observable
  String email;

  @observable
  List<IoniaGiftCard> giftCards;

  @observable
  CakePayVendorState merchantState;

  @computed
  int get countOfMerch => giftCards.where((giftCard) => !giftCard.isEmpty).length;

  @computed
  List<IoniaGiftCard> get activeMechs => giftCards.where((giftCard) => !giftCard.isEmpty).toList();

  @computed
  List<IoniaGiftCard> get redeemedMerchs =>
      giftCards.where((giftCard) => giftCard.isEmpty).toList();

  @action
  Future<void> logout() async => cakePayService.logout(email);

  @action
  Future<void> updateUserGiftCards() async {
    merchantState = CakePayVendorLoadingState();
    giftCards = await cakePayService.getCurrentUserGiftCardSummaries();
    merchantState = CakePayVendorLoadedState();
  }
}
