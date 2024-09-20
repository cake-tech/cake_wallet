import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

typedef OnConnectDevice = void Function(BuildContext, LedgerViewModel);

class ConnectDevicePageParams {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;

  ConnectDevicePageParams(
      {required this.walletType, required this.onConnectDevice});
}

class ConnectDevicePage extends BasePage {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final LedgerViewModel ledgerVM;

  ConnectDevicePage(ConnectDevicePageParams params, this.ledgerVM)
      : walletType = params.walletType,
        onConnectDevice = params.onConnectDevice;

  @override
  String get title => S.current.restore_title_from_hardware_wallet;

  @override
  Widget body(BuildContext context) =>
      ConnectDevicePageBody(walletType, onConnectDevice, ledgerVM);
}

class ConnectDevicePageBody extends StatefulWidget {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final LedgerViewModel ledgerVM;

  const ConnectDevicePageBody(
      this.walletType, this.onConnectDevice, this.ledgerVM);

  @override
  ConnectDevicePageBodyState createState() => ConnectDevicePageBodyState();
}

class ConnectDevicePageBodyState extends State<ConnectDevicePageBody> {
  // final ledger = Ledger(
  //   options: LedgerOptions(
  //     scanMode: ScanMode.balanced,
  //     maxScanDuration: const Duration(minutes: 5),
  //   ),
  //   onPermissionRequest: (_) async {
  //     Map<Permission, PermissionStatus> statuses = await [
  //       Permission.bluetoothScan,
  //       Permission.bluetoothConnect,
  //       Permission.bluetoothAdvertise,
  //     ].request();
  //
  //     return statuses.values.where((status) => status.isDenied).isEmpty;
  //   },
  // );

  var bleIsEnabled = true;
  var bleDevices = <LedgerDevice>[];
  var usbDevices = <LedgerDevice>[];

  late Timer? _usbRefreshTimer = null;
  late Timer? _bleRefreshTimer = null;
  late StreamSubscription<LedgerDevice>? _bleRefresh = null;
  late StreamSubscription<LedgerDevice>? _usbRefresh = null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bleRefreshTimer =
          Timer.periodic(Duration(seconds: 1), (_) => _refreshBleDevices());

      if (Platform.isAndroid) {
        _usbRefreshTimer =
            Timer.periodic(Duration(seconds: 1), (_) => _refreshUsbDevices());
      }
    });
  }

  @override
  void dispose() {
    _bleRefreshTimer?.cancel();
    _usbRefreshTimer?.cancel();
    _bleRefresh?.cancel();
    _usbRefresh?.cancel();
    super.dispose();
  }

  Future<void> _refreshUsbDevices() async {
    _usbRefresh = widget.ledgerVM
        .scanForUsbDevices()
        .listen((device) => setState(() => usbDevices.add(device)))
      ..onError((e) {
        throw e.toString();
      });
    _usbRefreshTimer?.cancel();
    _usbRefreshTimer = null;
  }

  Future<void> _refreshBleDevices() async {
    try {
      _bleRefresh = widget.ledgerVM
          .scanForBleDevices()
          .listen((device) => setState(() => bleDevices.add(device)))
        ..onError((e) {
          throw e.toString();
        });
      setState(() => bleIsEnabled = true);
      _bleRefreshTimer?.cancel();
      _bleRefreshTimer = null;
    } catch (e) {
      setState(() => bleIsEnabled = false);
    }
  }

  Future<void> _connectToDevice(LedgerDevice device) async {
    await widget.ledgerVM.connectLedger(device, widget.walletType);
    widget.onConnectDevice(context, widget.ledgerVM);
  }

  String _getDeviceTileLeading(LedgerBleDeviceInfo? deviceInfo) {
    switch (deviceInfo) {
      case LedgerBleDeviceInfo.nanoX:
        return 'assets/images/hardware_wallet/ledger_nano_x.png';
      case LedgerBleDeviceInfo.stax:
        return 'assets/images/hardware_wallet/ledger_stax.png';
      case LedgerBleDeviceInfo.flex:
        return 'assets/images/hardware_wallet/ledger_flex.png';
      default:
        return 'assets/images/hardware_wallet/ledger_nano_x.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
        height: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Text(
                  Platform.isIOS
                      ? S.of(context).connect_your_hardware_wallet_ios
                      : S.of(context).connect_your_hardware_wallet,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context)
                          .extension<CakeTextTheme>()!
                          .titleColor),
                  textAlign: TextAlign.center,
                ),
              ),
              // DeviceTile(
              //   onPressed: () => Navigator.of(context).push(
              //     MaterialPageRoute<void>(
              //       builder: (BuildContext context) => DebugDevicePage(),
              //     ),
              //   ),
              //   title: "Debug Ledger",
              //   leading: imageLedger,
              // ),
              if (!bleIsEnabled)
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Text(
                    S.of(context).ledger_please_enable_bluetooth,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context)
                            .extension<CakeTextTheme>()!
                            .titleColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (bleDevices.length > 0) ...[
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      S.of(context).bluetooth,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .extension<CakeTextTheme>()!
                            .titleColor,
                      ),
                    ),
                  ),
                ),
                ...bleDevices
                    .map(
                      (device) => Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: DeviceTile(
                          onPressed: () => _connectToDevice(device),
                          title: device.name,
                          leading: _getDeviceTileLeading(device.deviceInfo),
                          connectionType: device.connectionType,
                        ),
                      ),
                    )
                    .toList()
              ],
              if (usbDevices.length > 0) ...[
                Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Container(
                    width: double.infinity,
                    child: Text(
                      S.of(context).usb,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context)
                            .extension<CakeTextTheme>()!
                            .titleColor,
                      ),
                    ),
                  ),
                ),
                ...usbDevices
                    .map(
                      (device) => Padding(
                        padding: EdgeInsets.only(bottom: 20),
                        child: DeviceTile(
                          onPressed: () => _connectToDevice(device),
                          title: device.name,
                          leading: _getDeviceTileLeading(device.deviceInfo),
                          connectionType: device.connectionType,
                        ),
                      ),
                    )
                    .toList(),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
