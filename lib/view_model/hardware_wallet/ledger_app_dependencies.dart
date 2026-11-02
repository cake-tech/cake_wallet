import "dart:io";

import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/monero/monero.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page_params.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/tron/tron.dart";
import "package:cake_wallet/view_model/hardware_wallet/ledger_view_model_dependencies.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cake_wallet/zcash/zcash.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/hardware/device_connection_type.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart" as sdk;

LedgerViewModelDependencies ledgerAppDependencies(AppStore appStore) {
  HardwareWalletService service(WalletType type, sdk.LedgerConnection connection) {
    switch (type) {
      case WalletType.monero:
        return monero!.getLedgerHardwareWalletService(connection);
      case WalletType.bitcoin:
        return bitcoin!.getLedgerHardwareWalletService(connection, true);
      case WalletType.litecoin:
        return bitcoin!.getLedgerHardwareWalletService(connection, false);
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.getLedgerHardwareWalletService(connection);
      case WalletType.zcash:
        return zcash!.getLedgerHardwareWalletService(connection);
      case WalletType.tron:
        return tron!.getLedgerHardwareWalletService(connection);
      default:
        throw UnimplementedError();
    }
  }

  Future<void> initWallet(WalletBase wallet, sdk.LedgerConnection connection) {
    switch (wallet.type) {
      case WalletType.monero:
        return monero!.setLedgerConnection(wallet, connection);
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!.setHardwareWalletService(wallet, service(wallet.type, connection));
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.setHardwareWalletService(wallet, service(wallet.type, connection));
      case WalletType.zcash:
        return zcash!.setHardwareWalletService(wallet, service(wallet.type, connection));
      case WalletType.tron:
        return tron!.setHardwareWalletService(wallet, service(wallet.type, connection));
      default:
        throw BadWalletTypeException(
            "Unexpected wallet type: ${wallet.type} for ledger", wallet.type);
    }
  }

  void moneroDisconnected(bool suppressPrompt) {
    monero!.resetLedgerConnection();
    if (suppressPrompt) return;
    Navigator.of(navigatorKey.currentContext!).pushNamed(
      Routes.connectDevices,
      arguments: ConnectDevicePageParams(
        walletType: WalletType.monero,
        hardwareWalletType: HardwareWalletType.ledger,
        allowChangeWallet: true,
        isReconnect: true,
        onConnectDevice: (context, ledgerVM) {
          if (context.mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  return LedgerViewModelDependencies(
    currentWallet: () => appStore.wallet,
    supportsHardwareWallets: !isMoneroOnly ||
        DeviceConnectionType.supportedConnectionTypes(
          WalletType.monero,
          HardwareWalletType.ledger,
          isIOS: Platform.isIOS,
        ).isNotEmpty,
    getHardwareWalletService: service,
    initWallet: initWallet,
    clearTronService: (wallet) => tron!.clearHardwareWalletService(wallet),
    onMoneroDisconnected: moneroDisconnected,
  );
}
