import 'package:mobx/mobx.dart';

part 'seed_settings_store.g.dart';

class SeedSettingsStore = SeedSettingsStoreBase with _$SeedSettingsStore;

abstract class SeedSettingsStoreBase with Store {

  @observable
  String? passphrase;
}
