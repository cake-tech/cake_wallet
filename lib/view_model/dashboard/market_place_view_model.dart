import 'package:cake_wallet/ionia/ionia_service.dart';
import 'package:mobx/mobx.dart';

part 'market_place_view_model.g.dart';

class MarketPlaceViewModel = MarketPlaceViewModelBase with _$MarketPlaceViewModel;

abstract class MarketPlaceViewModelBase with Store {
    final IoniaService _ioniaService;

  MarketPlaceViewModelBase(this._ioniaService);


  Future<bool> isIoniaUserAuthenticated() async {
    return await _ioniaService.isLogined();
  }
}