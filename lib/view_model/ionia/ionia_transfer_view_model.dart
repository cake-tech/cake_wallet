import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'ionia_transfer_view_model.g.dart';

class IoniaTransferViewModel  = IoniaTransferViewModelBase with _$IoniaTransferViewModel;

abstract class IoniaTransferViewModelBase with Store {

  IoniaTransferViewModelBase({this.ioniaService, this.giftCard});

  final IoniaService ioniaService;

  final IoniaGiftCard giftCard;

  @observable
  String email;

  @action
  void share(String value) {
    email = value;
  }

}