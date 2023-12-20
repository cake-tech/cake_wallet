import 'package:cake_wallet/store/settings_store.dart';
import 'package:mobx/mobx.dart';

part 'tor_view_model.g.dart';

class TorViewModel = TorViewModelBase with _$TorViewModel;

abstract class TorViewModelBase with Store {

  TorViewModelBase(this._settingsStore);

  final SettingsStore _settingsStore;

  @action
  Future<void> updateStartOnLaunch(bool value) async {
    _settingsStore.shouldStartTorOnLaunch = value;
  }
}
