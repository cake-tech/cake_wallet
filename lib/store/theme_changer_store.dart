import 'package:cake_wallet/theme_changer.dart';
import 'package:mobx/mobx.dart';

part 'theme_changer_store.g.dart';

class ThemeChangerStore = ThemeChangerStoreBase with _$ThemeChangerStore;

abstract class ThemeChangerStoreBase with Store {
  ThemeChangerStoreBase({this.themeChanger});

  @observable
  ThemeChanger themeChanger;
}