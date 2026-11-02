import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart";

typedef OnConnectDevice = void Function(BuildContext, HardwareWalletViewModel);

class ConnectDevicePageParams {
  const ConnectDevicePageParams({
    required this.walletType,
    required this.hardwareWalletType,
    required this.onConnectDevice,
    this.allowChangeWallet = false,
    this.isReconnect = true,
  });

  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final bool isReconnect;
  final HardwareWalletType hardwareWalletType;
}
