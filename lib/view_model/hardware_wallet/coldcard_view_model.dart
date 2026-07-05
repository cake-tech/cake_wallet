import 'package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:coldcard_protocol/client.dart';
import 'package:coldcard_usb/coldcard_usb_transport.dart';
import 'package:coldcard_usb/ledger_usb_platform_interface.dart';
import 'package:cw_core/hardware/hardware_wallet_service.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';

class ColdcardViewModel extends HardwareWalletViewModel {
  HardwareWalletType get hardwareWalletType => HardwareWalletType.coldcardUsb;
  bool get isBleEnabled => false;
  bool get hasBluetooth => false;
  bool _isConnecting = false;

  ColdCardDevice? _dev;

  bool isConnected(WalletType type) {
    return _dev != null;
  }

  // Future<void> updateBleState();

  // Stream<HardwareWalletDevice> scanForBleDevices();

  // only returns first coldcard device found
  @override
  Future<List<HardwareWalletDevice>> getAllUsbDevices() async {
    final usbDevices = await ColdcardUsbPlatform.instance.getDevices();
    final found = usbDevices.any(
        (d) => d.vendorId == ColdCardDevice.coinkiteVid && d.productId == ColdCardDevice.ckccPid);
    return found ? [ColdcardHardwareWalletDevice()] : [];
  }

  // Future<void> stopScanning();

  Future<bool> connectDevice(HardwareWalletDevice device, WalletType type) async {
    if (!(device is ColdcardHardwareWalletDevice)) return false;
    if (_isConnecting) return false;
    _isConnecting = true;

    try {
      _dev = await ColdCardDevice.create(ColdcardUsbTransport());
      _isConnecting = false;
      return true;
    } catch (e) {
      printV(e);
    }

    _isConnecting = false;
    return false;
  }

  HardwareWalletService getHardwareWalletService(WalletType type) {
    if (type != WalletType.bitcoin) throw UnimplementedError();
    return bitcoin!.getColdcardHardwareWalletService(_dev!);
  }

  // Future<void> initWallet(WalletBase wallet);

  // String? interpretErrorCode(String error) => null;
}
