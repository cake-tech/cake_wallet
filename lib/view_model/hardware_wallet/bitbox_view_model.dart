import "dart:async";
import "dart:io";

import "package:bitbox_flutter/bitbox_flutter.dart" as sdk;
import "package:bitbox_flutter/ffi/bitbox_ffi.dart";
import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/evm/evm.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/widgets/hardware_wallet/bitbox_paring_sheet.dart";
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
import "package:flutter/material.dart";
import "package:ledger_flutter_plus/ledger_flutter_plus.dart" show UniversalBle, AvailabilityState;
import "package:mobx/mobx.dart";

part "bitbox_view_model.g.dart";

class BitboxViewModel = BitboxViewModelBase with _$BitboxViewModel;

abstract class BitboxViewModelBase extends HardwareWalletViewModel with Store {
  BitboxViewModelBase(AppStore appStore) {
    if (!isMoneroOnly) {
      reaction((_) => isBleEnabled, (_) {
        if (isBleEnabled) {
          _initBLE();
        }
      });

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
  StreamSubscription<sdk.BitboxConnectionStatus>? _statusChanges;

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

  bool _bleIsInitialized = false;

  Future<void> _initBLE() async {
    if (isBleEnabled && !_bleIsInitialized) {
      bleManager = sdk.BitboxBleConnectionManager();
      _bleIsInitialized = true;
    }
  }

  @override
  Future<void> updateBleState() async {
    final bleState = await UniversalBle.getBluetoothAvailabilityState();

    final newState = bleState == AvailabilityState.poweredOn;

    if (newState != isBleEnabled) {
      isBleEnabled = newState;
    }
  }

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() =>
      bleManager.scan().map(BitboxHardwareWalletDevice.new);

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() => usbManager.currentDevices
      .then((devices) => devices.map(BitboxHardwareWalletDevice.new).toList());

  @override
  Future<void> stopScanning() async {
    if (_bleIsInitialized) {
      await bleManager.stopScan();
    }
    if (!Platform.isIOS) {
      await usbManager.stopScan();
    }
  }

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

    StreamSubscription<BitboxEvent>? events;
    try {
      final appDocDir = await getAppDir();

      final bitBoxManager =
          device.connectionType == HardwareWalletConnectionType.ble ? bleManager : usbManager;

      _connection = await bitBoxManager.connect(device.device);
      printV("Got Connection", file: "${appDocDir.path}/error.txt");

      final channelHashVerified = Completer<bool>();
      events = bitBoxManager.events.listen((event) async {
        printV(event.event);
        if (event.event == "channelHashChanged" &&
            event.channelHash.isNotEmpty &&
            !event.channelHashVerified) {
          final verifiedChannelHash = await showModalBottomSheet<bool?>(
            context: navigatorKey.currentContext!,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            useSafeArea: true,
            builder: (_) => HardwareWalletBitboxParingSheet(paringCode: event.channelHash),
          );

          if (!channelHashVerified.isCompleted) {
            channelHashVerified.complete(verifiedChannelHash ?? false);
          }
        }
      });

      await _connection!.initBitBox();

      final isChannelHashVerified = await channelHashVerified.future;

      if (isChannelHashVerified) {
        await _connection!.channelHashVerify();
      } else {
        isConnecting = false;
        unawaited(disconnect());
        return false;
      }

      _statusChanges = _connection?.statusChanges.listen((e) {
        if (e == sdk.BitboxConnectionStatus.disconnected) {
          unawaited(disconnect());
        }
      });
      isConnecting = false;
      return true;
    } catch (e) {
      unawaited(disconnect());
      printV(e);
    } finally {
      unawaited(events?.cancel());
      printV("DONE!");
      isConnecting = false;
    }
    return false;
  }

  Future<void> disconnect() async {
    await _connection?.disconnect();
    _connection = null;
    await _statusChanges?.cancel();
    _statusChanges = null;
  }

  @override
  bool isConnected(WalletType type) => _connection != null;

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
        return bitcoin!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      default:
        throw BadWalletTypeException(
          "Unexpected wallet type: ${wallet.type} for bitbox",
          wallet.type,
        );
    }
  }
}
