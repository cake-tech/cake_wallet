import 'package:mobx/mobx.dart';

part 'fiat_convertation_store.g.dart';

class FiatConvertationStore = FiatConvertationStoreBase with _$FiatConvertationStore;

abstract class FiatConvertationStoreBase with Store {
  FiatConvertationStoreBase() {
    setPrice(0.0);
  }

  @observable
  double price;

  @action
  void setPrice(double price) {
    this.price = price;
  }
}