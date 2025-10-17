import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'deuro_view_model.g.dart';

class DEuroViewModel = DEuroViewModelBase with _$DEuroViewModel;

abstract class DEuroViewModelBase with Store {
  static BigInt get MIN_ACCRUED_INTEREST => BigInt.parse("1000000000000");

  const DEuroViewModelBase(this._settingsStore);

  final SettingsStore _settingsStore;

  @computed
  bool get isFistTime => _settingsStore.shouldShowDEuroDisclaimer;

  @action
  void acceptDisclaimer() => _settingsStore.shouldShowDEuroDisclaimer = false;
}
