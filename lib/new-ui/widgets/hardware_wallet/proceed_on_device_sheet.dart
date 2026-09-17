import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/digit_input.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/base_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/hardware_wallet/trezor_connect_view_model.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobx/mobx.dart';

class HardwareWalletProceedOnDeviceSheet extends StatefulWidget {
  const HardwareWalletProceedOnDeviceSheet({
    super.key,
    required this.hardwareWalletType,
    required this.trezorConnectVM,
    required this.onRetry,
  });

  final HardwareWalletType hardwareWalletType;
  final TrezorConnectViewModelBase trezorConnectVM;
  final void Function() onRetry;

  @override
  State<HardwareWalletProceedOnDeviceSheet> createState() =>
      _HardwareWalletProceedOnDeviceSheetState();
}

class _HardwareWalletProceedOnDeviceSheetState extends State<HardwareWalletProceedOnDeviceSheet> {
  TrezorParingState _paringState = TrezorParingState.initial;

  final DigitInputController _controller = DigitInputController();

  static const pinOpenDuration = Duration(milliseconds: 300);

  // you should probably check if there can be other pin lengths
  static const pinLength = 6;

  ReactionDisposer? paringStateReaction;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));

    _paringState = widget.trezorConnectVM.paringState;
    paringStateReaction = reaction((_) => widget.trezorConnectVM.paringState, (paringState) {
      if (paringState is SuccessTrezorParingState) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      setState(() => _paringState = paringState);
    });
  }

  @override
  void dispose() {
    super.dispose();
    paringStateReaction?.reaction.dispose();
  }

  bool get _isAwaitingPin => _paringState == TrezorParingState.enterPin;

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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      pageTitle,
                    ),
                  ),
                  trailingIcon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  trailingSemanticLabel: S.of(context).close,
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
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: DirectionalAnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    child: content,
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
                          semanticLabel: S.of(context).confirm,
                          onPressed: () =>
                              widget.trezorConnectVM.setParingPin(_controller.text.trim()),
                        ),
                      ),
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

  Widget get content {
    if (_paringState is InitialTrezorParingState || _paringState is EnterPinTrezorParingState) {
      return _enterPinCode();
    }

    if (_paringState is VerifyingPinTrezorParingState) return _verifyingCode();

    if (_paringState is FailTrezorParingState)
      return _errorBox((_paringState as FailTrezorParingState).message);

    return SizedBox.shrink(key: ValueKey(3));
  }

  void retry() {
    _controller.text = "";
    widget.onRetry();
  }

  String get pageTitle {
    if (_paringState is InitialTrezorParingState) return S.of(context).device_confirmation;
    if (_isAwaitingPin) return S.of(context).pairing_code;
    return "";
  }

  bool get hasFullPin => _controller.text.length == pinLength && _isAwaitingPin;

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

  Widget _verifyingCode() => Container(
        key: ValueKey(1),
        width: MediaQuery.of(context).size.width,
        child: Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 36),
            const SizedBox(),
            Text(
              "${S.of(context).verifying_code}...",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            Text(
              S.of(context).this_can_take_few_seconds,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          ],
        ),
      );

  Widget _errorBox(String errorText) => Container(
        key: ValueKey(2),
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 12,
            children: [
              const Spacer(),
              Icon(
                Icons.error_outline,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              Text(
                S.of(context).pairing_error,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                errorText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              NewPrimaryButton(
                onPressed: retry,
                text: S.of(context).try_again,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              )
            ],
          ),
        ),
      );

  Widget _enterPinCode() => Column(
        key: ValueKey(0),
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: pinOpenDuration,
            curve: Curves.easeOutCubic,
            width: _isAwaitingPin ? 40 : 100,
            height: _isAwaitingPin ? 40 : 100,
            child: CakeImageWidget(
              imageUrl: hardwareWalletIcon,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
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
                        "${S.of(context).pairing_code_desc_1}\n${S.of(context).pairing_code_desc_2}",
                      ),
                      DigitInput(
                        controller: _controller,
                        desiredLength: pinLength,
                      )
                    ],
                  )
                : Column(
                    key: ValueKey(0),
                    spacing: 12,
                    children: [
                      Text(
                        S.of(context).proceed_on_device,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          S.of(context).proceed_on_device_description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    ],
                  ),
          )
        ],
      );
}
