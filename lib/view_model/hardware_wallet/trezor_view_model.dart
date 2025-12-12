import 'dart:async';

import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:trezor_connect/trezor_connect.dart' as sdk;
import 'package:mobx/mobx.dart';

part 'trezor_view_model.g.dart';

class TrezorViewModel = TrezorViewModelBase with _$TrezorViewModel;

abstract class TrezorViewModelBase extends HardwareWalletViewModel with Store {
  final sdk.TrezorConnect trezorConnect;

  TrezorViewModelBase(this.trezorConnect);

  @override
  HardwareWalletType get hardwareWalletType => HardwareWalletType.trezor;

  @override
  @observable
  bool isBleEnabled = false;

  @override
  bool get hasBluetooth => false;

  @override
  Future<void> updateBleState() async {}

  @override
  Stream<HardwareWalletDevice> scanForBleDevices() => throw UnimplementedError();

  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() async => [];

  @override
  Future<void> stopScanning() async {}

  @override
  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async => true;

  @override
  bool get isConnected => true;

  @override
  HardwareWalletService getHardwareWalletService(WalletType type) {
    switch (type) {
      case WalletType.bitcoin:
        return bitcoin!.getTrezorHardwareWalletService(trezorConnect, true);
      case WalletType.litecoin:
        return bitcoin!.getTrezorHardwareWalletService(trezorConnect, false);
      case WalletType.evm:
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.getTrezorHardwareWalletService(trezorConnect);
      default:
        throw UnimplementedError();
    }
  }

  @override
  Future<void> initWallet(WalletBase wallet) async {
    switch (wallet.type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        return bitcoin!.setHardwareWalletService(wallet, await getHardwareWalletService(wallet.type));
      case WalletType.evm:
      case WalletType.ethereum:
      case WalletType.polygon:
        return evm!.setHardwareWalletService(wallet, await getHardwareWalletService(wallet.type));
      default:
        throw Exception('Unexpected wallet type: ${wallet.type}');
    }
  }
}
