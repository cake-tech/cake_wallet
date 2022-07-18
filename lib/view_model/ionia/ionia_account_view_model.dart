import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';

part 'ionia_account_view_model.g.dart';

class IoniaAccountViewModel = IoniaAccountViewModelBase with _$IoniaAccountViewModel;

abstract class IoniaAccountViewModelBase with Store {
  IoniaAccountViewModelBase({this.ioniaService}) {
    email = '';
    giftCards = [];
    ioniaService.getUserEmail().then((email) => this.email = email);
    updateUserGiftCards();
  }

  final IoniaService ioniaService;

  @observable
  String email;

  @observable
  List<IoniaGiftCard> giftCards;

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
    giftCards = await ioniaService.getCurrentUserGiftCardSummaries();
  }
}
