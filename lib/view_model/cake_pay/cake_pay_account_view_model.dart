import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:mobx/mobx.dart';

part 'cake_pay_account_view_model.g.dart';

class CakePayAccountViewModel = CakePayAccountViewModelBase with _$CakePayAccountViewModel;

abstract class CakePayAccountViewModelBase with Store {
  CakePayAccountViewModelBase({required this.cakePayService}) : email = '' {
    cakePayService.getUserEmail().then((email) => this.email = email ?? '');
  }

  final CakePayService cakePayService;

  @observable
  String email;

  @action
  Future<void> logout() async => cakePayService.logout(email);
}
