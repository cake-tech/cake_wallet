import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cake_wallet/ethereum/ethereum.dart';
import 'package:cake_wallet/polygon/polygon.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/wallet_type_utils.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/root_dir.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:bitbox_flutter/bitbox_flutter.dart' as sdk;
import 'package:mobx/mobx.dart';

part 'bitbox_view_model.g.dart';

class BitboxViewModel = BitboxViewModelBase with _$BitboxViewModel;

abstract class BitboxViewModelBase extends HardwareWalletViewModel with Store {
  late final sdk.BitboxManager bitboxManager;

  BitboxViewModelBase() {
    if (!Platform.isIOS && !isMoneroOnly) {
      bitboxManager = sdk.BitboxManager();
      }
  }

  @override
  @observable
  bool isBleEnabled = false;

  @override
  bool get hasBluetooth => Platform.isIOS && false; // TODO: remove when we enable bluetooth

  @override
  Future<void> updateBleState() async {}

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() => throw UnimplementedError();

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() => bitboxManager.devices
      .then((devices) => devices.map((d) => BitboxHardwareWalletDevice(d)).toList());

  @override
  Future<void> stopScanning() async {}

  @override
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (!(device is BitboxHardwareWalletDevice)) return false;
    if (_isConnecting) return false;
    _isConnecting = true;

    try {
      final appDocDir = await getAppDir();

      await bitboxManager.connect(device.device);
      printV("Got Connection", file: '${appDocDir.path}/error.txt');
      await bitboxManager.initBitBox();
      printV("Bitbox initialized!", file: '${appDocDir.path}/error.txt');
      await bitboxManager.channelHashVerify();
      printV("Bitbox channel-hash verified!", file: '${appDocDir.path}/error.txt');
      _isConnecting = false;
      return true;
    } catch (e) {
      printV(e);
    }
    _isConnecting = false;
    return false;
  }

  bool _isConnecting = false;

  @override
  bool get isConnected => false;

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoin!.getBitboxHardwareWalletService(bitboxManager, true);
      case WalletType.litecoin:
        return bitcoin!.getBitboxHardwareWalletService(bitboxManager, false);
      case WalletType.ethereum:
        return ethereum!.getBitboxHardwareWalletService(bitboxManager);
      case WalletType.polygon:
        return polygon!.getBitboxHardwareWalletService(bitboxManager);
      default:
        throw UnimplementedError();
    }
  }

  @override
  void initWallet(WalletBase wallet) {
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.ethereum:
        return ethereum!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      case WalletType.polygon:
        return polygon!.setHardwareWalletService(wallet, getHardwareWalletService(wallet.type));
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }
}
