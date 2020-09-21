import 'package:mobx/mobx.dart';

part 'fiat_conversion_store.g.dart';

class FiatConversionStore = FiatConversionStoreBase
    with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase() : price = 0.0;

  @observable
  double price;
}
