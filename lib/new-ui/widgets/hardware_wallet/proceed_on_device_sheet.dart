import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/digit_input.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HardwareWalletProceedOnDeviceSheet extends StatefulWidget {
  const HardwareWalletProceedOnDeviceSheet({super.key, required this.hardwareWalletType});

  final HardwareWalletType hardwareWalletType;

  @override
  State<HardwareWalletProceedOnDeviceSheet> createState() =>
      _HardwareWalletProceedOnDeviceSheetState();
}

class _HardwareWalletProceedOnDeviceSheetState extends State<HardwareWalletProceedOnDeviceSheet> {
  // TODO put this in the vm and remove from here (don't double up the state pls!)
  bool _isAwaitingPin = false;
  bool _isAwaitingConnection = false;
  final DigitInputController _controller = DigitInputController();

  static const pinOpenDuration = Duration(milliseconds: 300);

  // you should probably check if there can be other pin lengths
  static const pinLength = 6;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
              child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                ModalTopBar(
                  title: "",
                  leadingWidget: AnimatedSwitcher(
                    layoutBuilder: (currentChild, previousChildren) {
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: <Widget>[
                          ...previousChildren,
                          if (currentChild != null) currentChild,
                        ],
                      );
                    },
                    duration: pinOpenDuration,
                    child: Text(
                      key: ValueKey(pageTitle),
                      pageTitle,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  trailingIcon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onTrailingPressed: () => showPopUp(
                      context: context,
                      builder: (context) => AlertWithTwoActions(
                          alertTitle: S.of(context).are_you_sure_exit,
                          alertContent: S.of(context).hww_exit_desc,
                          leftButtonText: S.of(context).cancel,
                          rightButtonText: S.of(context).yes_exit,
                          rightAlertButtonStyle: AlertButtonStyle.error(context),
                          actionLeftButton: Navigator.of(context).pop,
                          actionRightButton: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          })),
                ),
                Expanded(
                  child: DirectionalAnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: _isAwaitingConnection
                        ? Container(
                            key: ValueKey(1),
                            width: MediaQuery.of(context).size.width,
                            child: Column(
                              spacing: 12,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                              // TODO remove gesture detector after vm actually works
                              // (for ui testing only)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isAwaitingConnection = false;
                                    });
                                  },
                                  child: CupertinoActivityIndicator(
                                    radius: 36,
                                  ),
                                ),
                                SizedBox(),
                                Text(
                                  "${S.of(context).verifying_code}...",
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                                ),
                                Text(
                                  S.of(context).this_can_take_few_seconds,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                )
                              ],
                            ),
                          )
                        : Column(
                            key: ValueKey(0),
                            spacing: 12,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            // TODO remove gesture detector after vm actually works
                              GestureDetector(
                                onTap: () => setState(() {
                                  _isAwaitingPin = !_isAwaitingPin;
                                }),
                                child: AnimatedContainer(
                                  duration: pinOpenDuration,
                                  curve: Curves.easeOutCubic,
                                  width: _isAwaitingPin ? 40 : 100,
                                  height: _isAwaitingPin ? 40 : 100,
                                  child: CakeImageWidget(
                                    imageUrl: hardwareWalletIcon,
                                    colorFilter: ColorFilter.mode(
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                        BlendMode.srcIn),
                                  ),
                                ),
                              ),
                              AnimatedSwitcher(
                                  duration: pinOpenDuration,
                                  switchInCurve: Curves.easeInCubic,
                                  switchOutCurve: Curves.easeOutCubic,
                                  child: _isAwaitingPin
                                      ? Column(
                                          spacing: 24,
                                          key: ValueKey(1),
                                          children: [
                                            Text(
                                                textAlign: TextAlign.center,
                                                "${S.of(context).pairing_code_desc_1}\n${S.of(context).pairing_code_desc_2}"),
                                            DigitInput(
                                                controller: _controller, desiredLength: pinLength)
                                          ],
                                        )
                                      : Column(
                                          key: ValueKey(0),
                                          spacing: 12,
                                          children: [
                                            Text(
                                              S.of(context).proceed_on_device,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500, fontSize: 20),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 20),
                                              child: Text(
                                                S.of(context).proceed_on_device_description,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant),
                                              ),
                                            )
                                          ],
                                        ))
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 24, right: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(),
                      AnimatedOpacity(
                          curve: Curves.easeOutQuad,
                          opacity: hasFullPin ? 1 : 0,
                          duration: pinOpenDuration,
                          child: ModernButton(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              iconColor: Theme.of(context).colorScheme.onPrimary,
                              size: 36,
                              icon: Icon(Icons.arrow_forward),
                              onPressed: () {
                                setState(() {
                                  _isAwaitingConnection = true;
                                });
                              })),
                    ],
                  ),
                )
              ],
            ),
          )),
        ),
      ),
    );
  }

  String get pageTitle {
    if(_isAwaitingConnection) return "";
    if(_isAwaitingPin) return S.of(context).pairing_code;
    return S.of(context).device_confirmation;
  }

  bool get hasFullPin =>
      _controller.text.length == pinLength && _isAwaitingPin && !_isAwaitingConnection;

  String? get hardwareWalletIcon {
    switch (widget.hardwareWalletType) {
      case HardwareWalletType.bitbox:
        return "assets/new-ui/hardware_wallets/device_bitbox.svg";
      case HardwareWalletType.ledger:
        return "assets/new-ui/hardware_wallets/device_ledger_nano_x.svg";
      case HardwareWalletType.trezor:
        return "assets/new-ui/hardware_wallets/device_trezor_safe_7.svg";
      case HardwareWalletType.cupcake:
        return "assets/images/cupcake.svg";
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        return "assets/images/hardware_wallet/device_qr.svg";
    }
  }
}
