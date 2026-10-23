import "dart:async";
import "dart:io";

import "package:bitbox_flutter/bitbox_flutter.dart" as sdk;
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cake_wallet/wallet_type_utils.dart";
import "package:cw_core/exceptions/cake_exception.dart";
import "package:cw_core/hardware/hardware_wallet_service.dart";
import "package:cw_core/root_dir.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:mobx/mobx.dart";

part "bitbox_view_model.g.dart";

class BitboxViewModel = BitboxViewModelBase with _$BitboxViewModel;

abstract class BitboxViewModelBase extends HardwareWalletViewModel with Store {
  BitboxViewModelBase(AppStore appStore) {
    if (!isMoneroOnly) {
      // reaction((_) => isBleEnabled, (_) {
      //   if (isBleEnabled) {
      //     _initBLE();
      //   }
      // });
      //
      // reaction((_) => appStore.wallet, (wallet) async {
      //   if (wallet != null && wallet.type != _connectingWalletType) {
      //     await close();
      //   }
      // });

      if (!Platform.isIOS) {
        usbManager = sdk.BitboxUsbConnectionManager();
      }
    }
  }

  late final sdk.BitboxConnectionManager bleManager;
  late final sdk.BitboxUsbConnectionManager usbManager;

  sdk.BitboxConnection? _connection;
  BitboxHardwareWalletDevice? _connectedDevice;
  Timer? _isConnectedTimer;

  @override
  HardwareWalletType get hardwareWalletType => HardwareWalletType.bitbox;

  @override
  @observable
  bool isBleEnabled = false;

  @override
  @observable
  bool isConnecting = false;

  @override
  bool get hasBluetooth => false;

  @override
  Future<void> updateBleState() async {}

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() => throw UnimplementedError();

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() => usbManager.currentDevices
      .then((devices) => devices.map(BitboxHardwareWalletDevice.new).toList());

  @override
  Future<void> stopScanning() async {}

  @override
  @action
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (device is! BitboxHardwareWalletDevice) {
      return false;
    }
    if (isConnecting) {
      return false;
    }
    isConnecting = true;

    try {
      final appDocDir = await getAppDir();

      _connection = await usbManager.connect(device.device);
      printV("Got Connection", file: "${appDocDir.path}/error.txt");

      _connectedDevice = device;
      _isConnectedTimer = Timer.periodic(const Duration(seconds: 1), (_) => _isStillConnected());
      isConnecting = false;
      return true;
    } catch (e) {
      printV(e);
    }
    isConnecting = false;
    _connectedDevice = null;
    _isConnectedTimer?.cancel();
    _isConnectedTimer = null;
    return false;
  }

  @override
  bool isConnected(WalletType type) => _connectedDevice != null;

  Future<void> _isStillConnected() async {
    final devices = await getAllUsbDevices();

    if (!devices.any((d) => d.name == _connectedDevice?.name)) {
      _connectedDevice = null;
      _isConnectedTimer?.cancel();
      _isConnectedTimer = null;
    }
  }

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoin!.getBitboxHardwareWalletService(_connection!, true);
      case WalletType.litecoin:
        return bitcoin!.getBitboxHardwareWalletService(_connection!, false);
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.getBitboxHardwareWalletService(_connection!);
      default:
        throw UnimplementedError();
    }
  }

  @override
  Future<void> initWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!
            .setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      default:
        throw BadWalletTypeException('Unexpected wallet type: ${wallet.type} for bitbox', wallet.type);
    }
  }
}
