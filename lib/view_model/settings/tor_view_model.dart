import 'dart:io';

import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/settings/tor_connection.dart';
import 'package:mobx/mobx.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:tor/tor.dart';

part 'tor_view_model.g.dart';

class TorViewModel = TorViewModelBase with _$TorViewModel;

enum TorConnectionStatus { connecting, connected, disconnected }

abstract class TorViewModelBase with Store {
  TorViewModelBase(this._settingsStore) {
    reaction((_) => torConnectionMode, (TorConnectionMode mode) async {
      if (mode == TorConnectionMode.enabled || mode == TorConnectionMode.onionOnly) {
        startTor();
      } else {
        stopTor();
      }
    });
  }

  final SettingsStore _settingsStore;

  @action
  Future<void> updateStartOnLaunch(bool value) async {
    _settingsStore.shouldStartTorOnLaunch = value;
  }

  @computed
  TorConnectionMode get torConnectionMode => _settingsStore.torConnectionMode;

  @observable
  TorConnectionStatus torConnectionStatus = TorConnectionStatus.disconnected;

  @action
  void setTorConnectionMode(TorConnectionMode mode) => _settingsStore.torConnectionMode = mode;

  @action
  Future<void> startTor() async {
    try {
      torConnectionStatus = TorConnectionStatus.connecting;

      await Tor.init();

      // start only if not already running:
      if (Tor.instance.port == -1) {
        await Tor.instance.enable();
      }

      _settingsStore.shouldStartTorOnLaunch = true;

      torConnectionStatus = TorConnectionStatus.connected;

      SocksTCPClient.setProxy(proxies: [
        ProxySettings(
          InternetAddress.loopbackIPv4,
          Tor.instance.port,
          password: null,
        ),
      ]);

      // connect to node through the proxy:
      final appStore = getIt.get<AppStore>();
      if (appStore.wallet != null) {
        final node = _settingsStore.getCurrentNode(appStore.wallet!.type);
        if (node.socksProxyAddress?.isEmpty ?? true) {
          node.socksProxyAddress = "${InternetAddress.loopbackIPv4.address}:${Tor.instance.port}";
        }
        appStore.wallet!.connectToNode(node: node);
      }
    } catch (e) {
      torConnectionStatus = TorConnectionStatus.disconnected;
    }
  }

  @action
  Future<void> stopTor() async {
    Tor.instance.disable();
    _settingsStore.shouldStartTorOnLaunch = false;
    torConnectionStatus = TorConnectionStatus.disconnected;
    SocksTCPClient.removeProxy();
  }
}
