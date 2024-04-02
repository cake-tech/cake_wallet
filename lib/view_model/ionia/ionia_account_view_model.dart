import 'package:cake_wallet/ionia/cake_pay_states.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/ionia/cake_pay_card.dart';

part 'ionia_account_view_model.g.dart';

class IoniaAccountViewModel = IoniaAccountViewModelBase with _$IoniaAccountViewModel;

abstract class IoniaAccountViewModelBase with Store {
  IoniaAccountViewModelBase({required this.ioniaService})
    : email = '',
      giftCards = [],
      merchantState = InitialCakePayVendorLoadingState() {
    ioniaService.getUserEmail().then((email) => this.email = email);
    updateUserGiftCards();
  }

  final IoniaService ioniaService;

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
  List<IoniaGiftCard> get redeemedMerchs => giftCards.where((giftCard) => giftCard.isEmpty).toList();

  @action
  void logout() {
    ioniaService.logout();
  }

  @action
  Future<void> updateUserGiftCards() async {
    merchantState = CakePayVendorLoadingState();
    giftCards = await ioniaService.getCurrentUserGiftCardSummaries();
    merchantState = CakePayVendorLoadedState();
  }
}
