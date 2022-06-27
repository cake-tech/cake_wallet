import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'ionia_account_view_model.g.dart';

class IoniaAccountViewModel = IoniaAccountViewModelBase with _$IoniaAccountViewModel;

abstract class IoniaAccountViewModelBase with Store {

  IoniaAccountViewModelBase({this.ioniaService});

  final IoniaService ioniaService;

  @action
  void logout(){
    ioniaService.logout();
  }

}