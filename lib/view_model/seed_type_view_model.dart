import 'package:cake_wallet/entities/seed_type.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:mobx/mobx.dart';

part 'seed_type_view_model.g.dart';

class SeedTypeViewModel = SeedTypeViewModelBase with _$SeedTypeViewModel;

abstract class SeedTypeViewModelBase with Store {
  SeedTypeViewModelBase(this._appStore);

  @computed
  SeedType get moneroSeedType => _appStore.settingsStore.moneroSeedType;

  @action
  void setMoneroSeedType(SeedType seedType) => _appStore.settingsStore.moneroSeedType = seedType;

  final AppStore _appStore;
}
