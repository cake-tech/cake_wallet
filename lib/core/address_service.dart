import "dart:async";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/auto_generate_subaddress_status.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/receive_page_option.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart" as mobx;

class AddressService {
  AddressService({required SettingsStore settingsStore}) : _settingsStore = settingsStore;

  final SettingsStore _settingsStore;

  AutoGenerateSubaddressStatus get autoGenerateSubaddressStatus =>
      _settingsStore.autoGenerateSubaddressStatus;

  bool isAutoGenerateSubaddressEnabled(WalletBase wallet, ReceivePageOption type) =>
      wallet.walletAddresses.autoGeneratesAddresses(type) &&
      autoGenerateSubaddressStatus != AutoGenerateSubaddressStatus.disabled;

  Stream<void> payjoinEndpointChanges(WalletBase wallet) {
    if (!wallet.hasPayjoinSupport) {
      return const Stream.empty();
    }

    mobx.ReactionDisposer? disposer;
    late final StreamController<void> controller;
    controller = StreamController<void>(
      onListen: () => disposer = mobx.reaction<String>(
        (_) => bitcoin!.getPayjoinEndpoint(wallet),
        (_) => controller.add(null),
      ),
      onCancel: () => disposer?.call(),
    );
    return controller.stream;
  }
}
