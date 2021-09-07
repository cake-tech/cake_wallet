import 'package:mobx/mobx.dart';

part 'yat_store.g.dart';

class YatStore = YatStoreBase with _$YatStore;

abstract class YatStoreBase with Store {
  YatStoreBase() : emoji = '';

  @observable
  String emoji;
}