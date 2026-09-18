import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cw_core/wallet_base.dart";
import "package:flutter/widgets.dart";

/// Makes sure the hardware device behind [wallet] is connected and its
/// session is bound to that wallet, showing the connect page first when there
/// is no connection yet.
///
/// Returns false when the user backed out of the connect page or the session
/// could not be bound; the calling flow must stop then. The view model has
/// already told the user why, unless they cancelled a prompt themselves.
///
/// A connected device is not enough on its own: with one Trezor and several
/// Cake wallets the live session may belong to another wallet, so "still
/// connected after the connect page" (the old re-check) must never be taken
/// as "ready to sign".
Future<bool> ensureHardwareWalletReady(
  BuildContext context,
  HardwareWalletViewModel hardwareWalletVM,
  WalletBase wallet, {
  bool isReconnect = false,
}) async {
  var ready = false;
  Future<void> init() async {
    ready = await hardwareWalletVM.tryInitWallet(wallet);
  }

  if (hardwareWalletVM.isConnected(wallet.type)) {
    await init();
    return ready;
  }

  final navigator = Navigator.of(context);
  await navigator.pushNamed(
    Routes.connectDevices,
    arguments: ConnectDevicePageParams(
      walletType: wallet.type,
      hardwareWalletType: wallet.walletInfo.hardwareWalletType!,
      onConnectDevice: (_, __) async {
        await init();
        if (navigator.mounted) navigator.pop();
      },
      isReconnect: isReconnect,
      reconnectWallet: wallet,
    ),
  );
  // Backing out of the connect page never runs the callback, so `ready`
  // stays false.
  return ready;
}
