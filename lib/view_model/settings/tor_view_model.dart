import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/view_model/settings/tor_connection.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';
import 'package:socks5_proxy/socks_client.dart';
import 'package:tor/tor.dart';

part 'tor_view_model.g.dart';

class TorViewModel = TorViewModelBase with _$TorViewModel;

enum TorConnectionStatus { connecting, connected, disconnected }

abstract class TorViewModelBase with Store {
  TorViewModelBase(this._settingsStore) {
    reaction((_) => torConnectionMode, (TorConnectionMode mode) async {
      if (mode == TorConnectionMode.enabled || mode == TorConnectionMode.torOnly) {
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

  Future<void> connectOrDisconnectNodeToProxy({required bool connect}) async {
    final appStore = getIt.get<AppStore>();
    if (appStore.wallet != null) {
      final node = _settingsStore.getCurrentNode(appStore.wallet!.type);
      if (connect && (node.socksProxyAddress?.isEmpty ?? true)) {
        node.socksProxyAddress = "${InternetAddress.loopbackIPv4.address}:${Tor.instance.port}";
      } else if (!connect) {
        node.socksProxyAddress = null;
      }

      bool torOnly = _settingsStore.torConnectionMode == TorConnectionMode.torOnly;
      if ([WalletType.bitcoin, WalletType.litecoin].contains(appStore.wallet!.type)) {
        bitcoin!.setTorOnly(appStore.wallet!, torOnly);
      }
      
      await appStore.wallet!.connectToNode(node: node);
    }
  }

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
      await connectOrDisconnectNodeToProxy(connect: true);
    } catch (e) {
      torConnectionStatus = TorConnectionStatus.disconnected;
    }
  }

  @action
  Future<void> stopTor() async {
    // Tor.instance.disable();// removed because we don't want to have to start tor again
    // setting the torConnectionMode to disabled will prevent anything from actually using the proxy
    _settingsStore.shouldStartTorOnLaunch = false;
    torConnectionStatus = TorConnectionStatus.disconnected;
    await connectOrDisconnectNodeToProxy(connect: false);
    SocksTCPClient.removeProxy();
  }
}
