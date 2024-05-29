import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'cake_features_view_model.g.dart';

class CakeFeaturesViewModel = CakeFeaturesViewModelBase with _$CakeFeaturesViewModel;

abstract class CakeFeaturesViewModelBase with Store {
  final IoniaService _ioniaService;

  CakeFeaturesViewModelBase(this._ioniaService);

  Future<bool> isIoniaUserAuthenticated() async {
    return await _ioniaService.isLogined();
  }
}
