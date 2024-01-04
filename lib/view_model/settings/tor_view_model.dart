import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/settings/tor_connection.dart';
import 'package:mobx/mobx.dart';
import 'package:tor/tor.dart';

part 'tor_view_model.g.dart';

class TorViewModel = TorViewModelBase with _$TorViewModel;

enum TorConnectionStatus { connecting, connected, disconnected }

abstract class TorViewModelBase with Store {
  TorViewModelBase(this._settingsStore);

  final SettingsStore _settingsStore;

  @action
  Future<void> updateStartOnLaunch(bool value) async {
    _settingsStore.shouldStartTorOnLaunch = value;
  }

  @computed
  TorConnectionMode get torConnectionMode => _settingsStore.torConnectionMode;

  @action
  void setTorConnectionMode(TorConnectionMode mode) => _settingsStore.torConnectionMode = mode;

  // @computed
  // bool get isTorConnected =>
  //     (_settingsStore.torConnectionMode == TorConnectionMode.enabled ||
  //         _settingsStore.torConnectionMode == TorConnectionMode.onionOnly) &&
  //     (Tor.instance.port != -1);

  @computed
  TorConnectionStatus get torConnectionStatus {

    if (_settingsStore.torConnectionMode == TorConnectionMode.disabled) {
      return TorConnectionStatus.disconnected;
    }
    
    if (Tor.instance.port == -1 && Tor.instance.started) {
      return TorConnectionStatus.connecting;
    }

    if (Tor.instance.port != -1) {
      return TorConnectionStatus.connected;
    }

    return TorConnectionStatus.disconnected;
  }
  
}
