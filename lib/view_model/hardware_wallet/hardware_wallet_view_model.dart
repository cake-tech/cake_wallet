import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/connect_device/connect_device_page_params.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/widgets.dart";

abstract class HardwareWalletViewModel {
  HardwareWalletType get hardwareWalletType;
  bool get isBleEnabled;
  bool get hasBluetooth;
  bool get isConnecting;

  bool isConnected(WalletType type);

  Future<void> updateBleState();

  Stream<HardwareWalletDevice> scanForBleDevices();

  Future<List<HardwareWalletDevice>> getAllUsbDevices();

  Future<List<HardwareWalletDevice>> getConnectedBleDevices() async => [];

  Future<void> stopScanning();

  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type);

  HardwareWalletService getHardwareWalletService(WalletType type);

  Future<void> initWallet(WalletBase wallet);

  String? interpretErrorCode(String error) => null;

  Future<void> close() async {}

  Future<bool> ensureDeviceConnection(BuildContext context, WalletBase wallet) async {
    if (!context.mounted) {
      return false;
    }

    if (wallet.isHardwareWallet) {
      if (!isConnected(wallet.walletInfo.type)) {
        Object? initializationError;
        StackTrace? initializationStack;
        var initializationStarted = false;
        var completedOnConnectionRoute = false;
        await Navigator.of(context).pushNamed(
          Routes.connectDevices,
          arguments: ConnectDevicePageParams(
            walletType: wallet.walletInfo.type,
            hardwareWalletType: wallet.walletInfo.hardwareWalletType!,
            onConnectDevice: (pageContext, hwwVM) async {
              if (initializationStarted || !pageContext.mounted) return;
              final route = ModalRoute.of(pageContext);
              if (route?.isCurrent != true) return;
              initializationStarted = true;
              try {
                await hwwVM.initWallet(wallet);
              } catch (error, stack) {
                initializationError = error;
                initializationStack = stack;
              }
              if (pageContext.mounted && route!.isCurrent) {
                completedOnConnectionRoute = true;
                Navigator.of(pageContext).pop();
              }
            },
            isReconnect: false,
          ),
        );
        if (!completedOnConnectionRoute) {
          return false;
        }
        if (initializationError != null) {
          Error.throwWithStackTrace(initializationError!, initializationStack!);
        }
        if (!isConnected(wallet.walletInfo.type)) {
          return false;
        }
      } else {
        await initWallet(wallet);
      }
    }

    return true;
  }
}
