import 'dart:async';
import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/connect_device/widgets/device_tile.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_steps_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:ledger_flutter_plus/ledger_flutter_plus.dart';

typedef OnConnectDevice = void Function(BuildContext, LedgerViewModel);

class ConnectDevicePageParams {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final bool isReconnect;

  ConnectDevicePageParams({
    required this.walletType,
    required this.onConnectDevice,
    this.allowChangeWallet = false,
    this.isReconnect = true,
  });
}

class ConnectDevicePage extends BasePage {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final bool isReconnect;
  final LedgerViewModel ledgerVM;

  ConnectDevicePage(ConnectDevicePageParams params, this.ledgerVM)
      : walletType = params.walletType,
        onConnectDevice = params.onConnectDevice,
        allowChangeWallet = params.allowChangeWallet,
        isReconnect = params.isReconnect;

  @override
  String get title => isReconnect
      ? S.current.reconnect_your_hardware_wallet
      : S.current.restore_title_from_hardware_wallet;

  @override
  Widget? leading(BuildContext context) =>
      !isReconnect ? super.leading(context) : null;

  @override
  Widget body(BuildContext context) => PopScope(
      canPop: !isReconnect,
      child: ConnectDevicePageBody(
        walletType,
        onConnectDevice,
        allowChangeWallet,
        ledgerVM,
        currentTheme,
      ));
}

class ConnectDevicePageBody extends StatefulWidget {
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final LedgerViewModel ledgerVM;
  final MaterialThemeBase currentTheme;

  const ConnectDevicePageBody(
    this.walletType,
    this.onConnectDevice,
    this.allowChangeWallet,
    this.ledgerVM,
    this.currentTheme,
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

  bool longWait = false;
  Timer? _longWaitTimer;

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

      _longWaitTimer = Timer(Duration(seconds: 10), () {
        if (widget.ledgerVM.bleIsEnabled && bleDevices.isEmpty)
          setState(() => longWait = true);
      });
    });
  }

  @override
  void dispose() {
    _bleRefreshTimer?.cancel();
    _bleStateTimer?.cancel();
    _usbRefreshTimer?.cancel();
    _bleRefresh?.cancel();
    _longWaitTimer?.cancel();

    widget.ledgerVM.stopScanning();
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
        _bleRefresh =
            widget.ledgerVM.scanForBleDevices().listen((device) => setState(() {
                  bleDevices.add(device);
                  if (longWait) longWait = false;
                }))
              ..onError((e) {
                throw e.toString();
              });
        _bleRefreshTimer?.cancel();
        _bleRefreshTimer = null;
      }
    } catch (e) {
      printV(e);
    }
  }

  Future<void> _connectToDevice(LedgerDevice device) async {
    final isConnected =
        await widget.ledgerVM.connectLedger(device, widget.walletType);
    if (isConnected) widget.onConnectDevice(context, widget.ledgerVM);
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
    return Container(
      width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    child: Text(
                      Platform.isAndroid
                          ? S.of(context).connect_your_hardware_wallet
                          : S.of(context).connect_your_hardware_wallet_ios,
                      style:  Theme.of(context)
                              .textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Offstage(
                    offstage: !longWait,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
                      child: Text(
                        S.of(context).if_you_dont_see_your_device,
                        style:  Theme.of(context)
                                .textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Observer(
                    builder: (_) => Offstage(
                      offstage: widget.ledgerVM.bleIsEnabled,
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: 20, right: 20, bottom: 20),
                        child: Text(
                          S.of(context).ledger_please_enable_bluetooth,
                          style:  Theme.of(context)
                                  .textTheme.titleMedium,
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
                          style:  Theme.of(context)
                                .textTheme.bodyMedium,
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
                          style:  Theme.of(context)
                                .textTheme.bodyMedium,
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
                      color: Theme.of(context)
                          .colorScheme.primary,
                      textColor: Theme.of(context)
                          .colorScheme.onPrimary,
                      onPressed: _onChangeWallet,
                    )
                  ],
                ],
              ),
            ),
          ),
          PrimaryButton(
            text: S.of(context).how_to_connect,
            color: Theme.of(context).colorScheme.surfaceContainer,
            textColor: Theme.of(context).colorScheme.onSecondaryContainer,
            onPressed: () => _onHowToConnect(context),
          )
        ],
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

  void _onHowToConnect(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext bottomSheetContext) => InfoStepsBottomSheet(
        titleText: S.of(context).how_to_connect,
        currentTheme: widget.currentTheme,
        steps: [
          InfoStep('${S.of(context).step} 1', S.of(context).connect_hw_info_step_1),
          InfoStep('${S.of(context).step} 2', S.of(context).connect_hw_info_step_2),
          InfoStep('${S.of(context).step} 3', S.of(context).connect_hw_info_step_3),
          InfoStep('${S.of(context).step} 4', S.of(context).connect_hw_info_step_4),
        ],
      ),
    );
  }
}
