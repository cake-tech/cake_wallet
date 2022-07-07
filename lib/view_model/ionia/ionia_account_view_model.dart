import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';

part 'ionia_account_view_model.g.dart';

class IoniaAccountViewModel = IoniaAccountViewModelBase with _$IoniaAccountViewModel;

abstract class IoniaAccountViewModelBase with Store {
  IoniaAccountViewModelBase({this.ioniaService}) {
    email = '';
    merchs = [];
    ioniaService.getUserEmail().then((email) => this.email = email);
    ioniaService.getCurrentUserGiftCardSummaries().then((merchs) => this.merchs = merchs);
  }

  final IoniaService ioniaService;

  @observable
  String email;

  @observable
  List<IoniaGiftCard> merchs;

  @computed
  int get countOfMerch => merchs.where((merch) => merch.isActive).length;

  @computed
  List<IoniaGiftCard> get activeMechs => merchs.where((merch) => merch.isActive).toList();

  @computed
  List<IoniaGiftCard> get redeemedMerchs => merchs.where((merch) => !merch.isActive).toList();

  @action
  void logout() {
    ioniaService.logout();
  }
}
