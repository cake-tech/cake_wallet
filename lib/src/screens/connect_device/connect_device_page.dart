import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/wallet_list_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

typedef OnConnectDevice = void Function(BuildContext, LedgerViewModel);

class ConnectDevicePageParams {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;

  ConnectDevicePageParams({
    required this.walletType,
    required this.onConnectDevice,
    this.allowChangeWallet = false,
  });
}

class ConnectDevicePage extends BasePage {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final LedgerViewModel ledgerVM;

  ConnectDevicePage(ConnectDevicePageParams params, this.ledgerVM)
      : walletType = params.walletType,
        onConnectDevice = params.onConnectDevice,
        allowChangeWallet = params.allowChangeWallet;

  @override
  String get title => S.current.restore_title_from_hardware_wallet;

  @override
  Widget body(BuildContext context) => ConnectDevicePageBody(
      walletType, onConnectDevice, allowChangeWallet, ledgerVM);
}

class ConnectDevicePageBody extends StatefulWidget {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final LedgerViewModel ledgerVM;

  const ConnectDevicePageBody(
    this.walletType,
    this.onConnectDevice,
    this.allowChangeWallet,
    this.ledgerVM,
  );

  @override
  ConnectDevicePageBodyState createState() => ConnectDevicePageBodyState();
}

class ConnectDevicePageBodyState extends State<ConnectDevicePageBody> {
  var bleDevices = <LedgerDevice>[];
  var usbDevices = <LedgerDevice>[];

  late Timer? _usbRefreshTimer = null;
  late Timer? _bleRefreshTimer = null;
  late Timer? _bleStateTimer = null;
  late StreamSubscription<LedgerDevice>? _bleRefresh = null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bleStateTimer = Timer.periodic(
          Duration(seconds: 1), (_) => widget.ledgerVM.updateBleState());

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
    _bleStateTimer?.cancel();
    _usbRefreshTimer?.cancel();
    _bleRefresh?.cancel();
    super.dispose();
  }

  Future<void> _refreshUsbDevices() async {
    final dev = await widget.ledgerVM.ledgerPlusUSB.devices;
    if (usbDevices.length != dev.length) setState(() => usbDevices = dev);
    // _usbRefresh = widget.ledgerVM
    //     .scanForUsbDevices()
    //     .listen((device) => setState(() => usbDevices.add(device)))
    //   ..onError((e) {
    //     throw e.toString();
    //   });
    // Keep polling until the lfp lib gets updated
    // _usbRefreshTimer?.cancel();
    // _usbRefreshTimer = null;
  }

  Future<void> _refreshBleDevices() async {
    try {
      if (widget.ledgerVM.bleIsEnabled) {
        _bleRefresh = widget.ledgerVM
            .scanForBleDevices()
            .listen((device) => setState(() => bleDevices.add(device)))
          ..onError((e) {
            throw e.toString();
          });
        _bleRefreshTimer?.cancel();
        _bleRefreshTimer = null;
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _connectToDevice(LedgerDevice device) async {
    await widget.ledgerVM.connectLedger(device, widget.walletType);
    widget.onConnectDevice(context, widget.ledgerVM);
  }

  String _getDeviceTileLeading(LedgerDeviceType deviceInfo) {
    switch (deviceInfo) {
      case LedgerDeviceType.nanoX:
        return 'assets/images/hardware_wallet/ledger_nano_x.png';
      case LedgerDeviceType.stax:
        return 'assets/images/hardware_wallet/ledger_stax.png';
      case LedgerDeviceType.flex:
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
              Observer(
                builder: (_) => Offstage(
                  offstage: widget.ledgerVM.bleIsEnabled,
                  child: Padding(
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
                        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
              ],
              if (widget.allowChangeWallet) ...[
                PrimaryButton(
                  text: S.of(context).wallets,
                  color: Theme.of(context).extension<WalletListTheme>()!.createNewWalletButtonBackgroundColor,
                  textColor: Theme.of(context).extension<WalletListTheme>()!.restoreWalletButtonTextColor,
                  onPressed: _onChangeWallet,
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onChangeWallet() {
    Navigator.of(context).pushNamed(
      Routes.walletList,
      arguments: (BuildContext context) => Navigator.of(context)
          .pushNamedAndRemoveUntil(Routes.dashboard, (route) => false),
    );
  }
}
