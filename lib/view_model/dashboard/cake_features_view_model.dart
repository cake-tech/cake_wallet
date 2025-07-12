import 'package:cake_wallet/cake_pay/src/services/cake_pay_service.dart';
import 'package:mobx/mobx.dart';

part 'cake_features_view_model.g.dart';

class CakeFeaturesViewModel = CakeFeaturesViewModelBase with _$CakeFeaturesViewModel;

abstract class CakeFeaturesViewModelBase with Store {
  final CakePayService _cakePayService;

  CakeFeaturesViewModelBase(this._cakePayService);

  Future<bool> isIoniaUserAuthenticated() async {
    return await _cakePayService.isLogged();
  }
}
