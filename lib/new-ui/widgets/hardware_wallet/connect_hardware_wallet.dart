import "package:cake_wallet/routes.dart" show Routes;
import "package:cake_wallet/src/screens/connect_device/connect_device_page.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cake_wallet/view_model/hardware_wallet/trezor_connect_view_model.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/material.dart";

Future<bool> connectHardwareWallet(
  BuildContext context,
  WalletBase wallet,
  HardwareWalletViewModel hardwareWalletViewModel,
) async {
  if (hardwareWalletViewModel is TrezorConnectViewModel &&
      wallet.type == WalletType.bitcoin &&
      hardwareWalletViewModel.isConnected(WalletType.bitcoin) &&
      !hardwareWalletViewModel.isSessionFor(wallet)) {
    // The live session belongs to another wallet (passphrase); open one for this wallet
    await hardwareWalletViewModel.dropSession();
  }

  if (hardwareWalletViewModel.isConnected(wallet.type)) {
    await hardwareWalletViewModel.initWallet(wallet);
    return true;
  }

  if (hardwareWalletViewModel is TrezorConnectViewModel && wallet.type == WalletType.bitcoin) {
    hardwareWalletViewModel.prepareReconnect(wallet);
  }

  await Navigator.of(context).pushNamed(
    Routes.connectDevices,
    arguments: ConnectDevicePageParams(
      walletType: wallet.type,
      hardwareWalletType: wallet.walletInfo.hardwareWalletType!,
      onConnectDevice: (_, __) {
        hardwareWalletViewModel.initWallet(wallet);
        Navigator.of(context).pop();
      },
      isReconnect: false,
    ),
  );
  if (hardwareWalletViewModel is TrezorConnectViewModel) {
    hardwareWalletViewModel.cancelReconnect();
  }

  // Recheck to handle tap-backs
  return hardwareWalletViewModel.isConnected(wallet.type);
}
