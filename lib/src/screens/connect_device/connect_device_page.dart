import "dart:async";
import "dart:io";

import "package:cake_wallet/entities/hardware_wallet/hardware_wallet_device.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/main.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/bottom_sheet/info_steps_bottom_sheet_widget.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/themes/core/material_base_theme.dart";
import "package:cake_wallet/utils/responsive_layout_util.dart";
import "package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

typedef OnConnectDevice = void Function(BuildContext, HardwareWalletViewModel);

class ConnectDevicePageParams {
  const ConnectDevicePageParams({
    required this.walletType,
    required this.hardwareWalletType,
    required this.onConnectDevice,
    this.allowChangeWallet = false,
    this.isReconnect = true,
  });

  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final bool isReconnect;
  final HardwareWalletType hardwareWalletType;
}

class ConnectDevicePage extends BasePage {
  ConnectDevicePage(ConnectDevicePageParams params, this.hardwareWalletVM)
      : walletType = params.walletType,
        onConnectDevice = params.onConnectDevice,
        allowChangeWallet = params.allowChangeWallet || params.isReconnect,
        isReconnect = params.isReconnect;
  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final bool isReconnect;
  final HardwareWalletViewModel hardwareWalletVM;

  @override
  String get title => isReconnect
      ? S.current.reconnect_your_hardware_wallet
      : S.current.restore_title_from_hardware_wallet;

  @override
  Widget? leading(BuildContext context) => !isReconnect ? super.leading(context) : null;

  @override
  Widget body(BuildContext context) => PopScope(
        canPop: !isReconnect,
        child: ConnectDevicePageBody(
          walletType,
          onConnectDevice,
          hardwareWalletVM,
          currentTheme,
          allowChangeWallet: allowChangeWallet,
        ),
      );
}

class ConnectDevicePageBody extends StatefulWidget {
  const ConnectDevicePageBody(
    this.walletType,
    this.onConnectDevice,
    this.hardwareWalletVM,
    this.currentTheme, {
    this.allowChangeWallet = false,
  });

  final WalletType walletType;
  final OnConnectDevice onConnectDevice;
  final bool allowChangeWallet;
  final HardwareWalletViewModel hardwareWalletVM;
  final MaterialThemeBase currentTheme;

  @override
  ConnectDevicePageBodyState createState() => ConnectDevicePageBodyState();
}

class ConnectDevicePageBodyState extends State<ConnectDevicePageBody> {
  var bleDevices = <HardwareWalletDevice>[];
  var usbDevices = <HardwareWalletDevice>[];

  List<HardwareWalletDevice> get allDevices => [...bleDevices, ...usbDevices];

  Timer? _usbRefreshTimer;
  Timer? _bleRefreshTimer;
  Timer? _bleStateTimer;
  StreamSubscription<HardwareWalletDevice>? _bleRefresh;

  bool longWait = false;
  Timer? _longWaitTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bleStateTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => widget.hardwareWalletVM.updateBleState(),
      );

      _bleRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshBleDevices());

      if (Platform.isAndroid) {
        _usbRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshUsbDevices());
      }

      if (widget.hardwareWalletVM.hasBluetooth) {
        _longWaitTimer = Timer(const Duration(seconds: 10), () {
          if (widget.hardwareWalletVM.isBleEnabled && bleDevices.isEmpty) {
            setState(() => longWait = true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bleRefreshTimer?.cancel();
    _bleStateTimer?.cancel();
    _usbRefreshTimer?.cancel();
    _bleRefresh?.cancel();
    _longWaitTimer?.cancel();

    widget.hardwareWalletVM.stopScanning();
    _isConnectPressed = false;
    super.dispose();
  }

  var _isRefreshingUsb = false;
  Future<void> _refreshUsbDevices() async {
    if (_isRefreshingUsb) {
      return;
    }
    _isRefreshingUsb = true;
    try {
      final dev = await widget.hardwareWalletVM.getAllUsbDevices();

      if (usbDevices.length != dev.length) {
        setState(() => usbDevices = dev);
      }
    } catch(e) {
      printV(e);
    }
    _isRefreshingUsb = false;
  }

  Future<void> _refreshBleDevices() async {
    try {
      if (widget.hardwareWalletVM.isBleEnabled) {
        _bleRefresh = widget.hardwareWalletVM.scanForBleDevices().listen(
              (device) => setState(() {
                bleDevices.add(device);
                if (longWait) {
                  longWait = false;
                }
              }),
            )..onError((e) {
            printV(e);
          });
        _bleRefreshTimer?.cancel();
        _bleRefreshTimer = null;
      }
    } catch (e) {
      printV(e);
    }
  }

  var _isConnectPressed = false;

  Future<void> _connectToDevice(HardwareWalletDevice device) async {
    if (_isConnectPressed) {
      return;
    }

    _isConnectPressed = true;
    try {
      final isConnected = await widget.hardwareWalletVM.connectDevice(device, widget.walletType);
      _isConnectPressed = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isConnected) {
          widget.onConnectDevice(navigatorKey.currentContext!, widget.hardwareWalletVM);
        }
      });
    } catch (_) {
      _isConnectPressed = false;
    }
  }

  String _getDeviceTileLeading(HardwareWalletDeviceType deviceType) {
    printV(deviceType);
    switch (deviceType) {
      case HardwareWalletDeviceType.ledgerNanoX:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletDeviceType.ledgerNanoGen5:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_gen_5.svg";
      case HardwareWalletDeviceType.ledgerStax:
        return "assets/new-ui/hardware_wallets/device_ledger_stax.svg";
      case HardwareWalletDeviceType.ledgerFlex:
        return "assets/new-ui/hardware_wallets/device_ledger_flex.svg";
      case HardwareWalletDeviceType.BitBox02:
      case HardwareWalletDeviceType.BitBox02Nova:
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletDeviceType.trezorModelOne:
        return "assets/new-ui/hardware_wallets/device_trezor_model_one.svg";
      case HardwareWalletDeviceType.trezorModelT:
        return "assets/new-ui/hardware_wallets/device_trezor_model_t.svg";
      case HardwareWalletDeviceType.trezorSafe3:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_3.svg";
      case HardwareWalletDeviceType.trezorSafe5:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_5.svg";
      case HardwareWalletDeviceType.trezorSafe7:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_7.svg";

      default:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
    }
  }

  String get description {
    if (!Platform.isAndroid) {
      return S.of(context).connect_your_hardware_wallet_ble;
    }

    if (widget.hardwareWalletVM.hasBluetooth) {
      return S.of(context).connect_your_hardware_wallet;
    }

    return S.of(context).connect_your_hardware_wallet_usb;
  }

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: ResponsiveLayoutUtilBase.kDesktopMaxWidthConstraint,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    spacing: 24,
                    children: [
                      const CakeImageWidget(imageUrl: "assets/new-ui/hardware_wallet.svg"),
                      Text(
                        description,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      Observer(
                        builder: (_) => Offstage(
                          offstage: widget.hardwareWalletVM.isBleEnabled ||
                              !widget.hardwareWalletVM.hasBluetooth,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                            child: Text(
                              S.of(context).ledger_please_enable_bluetooth,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final item = allDevices[index];
                            return GestureDetector(
                              onTap: () => _connectToDevice(item),
                              behavior: HitTestBehavior.opaque,
                              child: SizedBox(
                                height: 48,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        spacing: 12,
                                        children: [
                                          Observer(
                                            builder: (_) {
                                              if (widget.hardwareWalletVM.isConnecting) {
                                                return CupertinoActivityIndicator(
                                                  animating: true,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                  radius: 12,
                                                );
                                              }

                                              return CakeImageWidget(
                                                imageUrl: _getDeviceTileLeading(item.type),
                                                width: 24,
                                                height: 24,
                                                colorFilter: ColorFilter.mode(
                                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                                  BlendMode.srcIn,
                                                ),
                                              );
                                            },
                                          ),
                                          Text(item.name),
                                        ],
                                      ),
                                      Row(
                                        spacing: 12,
                                        children: [
                                          if (item.connectionType ==
                                              HardwareWalletConnectionType.ble)
                                            CakeImageWidget(
                                              imageUrl: "assets/new-ui/bluetooth.svg",
                                              width: 24,
                                              height: 24,
                                              colorFilter: ColorFilter.mode(
                                                Theme.of(context).colorScheme.primary,
                                                BlendMode.srcIn,
                                              ),
                                            ),
                                          CakeImageWidget(
                                            imageUrl: "assets/new-ui/arrow_forward.svg",
                                            height: 16,
                                            colorFilter: ColorFilter.mode(
                                              Theme.of(context).colorScheme.onSurfaceVariant,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) => Container(
                            height: 1,
                            color: Theme.of(context).colorScheme.surfaceContainerHigh,
                          ),
                          itemCount: allDevices.length,
                        ),
                      ),
                      if (widget.allowChangeWallet) ...[
                        PrimaryButton(
                          text: S.of(context).wallets,
                          color: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                          onPressed: _onChangeWallet,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              NewPrimaryButton(
                text: S.of(context).how_to_connect,
                color: Theme.of(context).colorScheme.surfaceContainer,
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: () => _onHowToConnect(context),
              ),
            ],
          ),
        ),
      );

  void _onChangeWallet() {
    Navigator.of(context).pushNamed(
      Routes.walletList,
      arguments: (BuildContext context) =>
          Navigator.of(context).pushNamedAndRemoveUntil(Routes.dashboard, (route) => false),
    );
  }

  void _onHowToConnect(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => InfoStepsBottomSheet(
        titleText: S.of(context).how_to_connect,
        steps: [
          InfoStep(
            "assets/images/wallet_connect_step_icons/step1_power.svg",
            S.of(context).connect_hw_info_step_1,
          ),
          InfoStep(
            "assets/images/wallet_connect_step_icons/step2_connect.svg",
            S.of(context).connect_hw_info_step_2,
          ),
          InfoStep(
            "assets/images/wallet_connect_step_icons/step3_unlock.svg",
            S.of(context).connect_hw_info_step_3,
          ),
          InfoStep(
            "assets/images/wallet_connect_step_icons/step4_select.svg",
            S.of(context).connect_hw_info_step_4,
          ),
        ],
      ),
    );
  }
}
