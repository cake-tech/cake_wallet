import "dart:async";

import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_toggle.dart";
import "package:cake_wallet/src/screens/connect_device/monero_hardware_wallet_passphrase_input.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/bordered_svg.dart";
import "package:cake_wallet/new-ui/widgets/digit_input.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/new-ui/widgets/send_page/directional_switcher.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/base_alert_dialog.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:cake_wallet/view_model/hardware_wallet/trezor_connect_view_model.dart";
import "package:cw_core/wallet_info.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:mobx/mobx.dart";

class HardwareWalletProceedOnDeviceSheet extends StatefulWidget {
  const HardwareWalletProceedOnDeviceSheet({
    required this.hardwareWalletType,
    required this.trezorConnectVM,
    super.key,
  });

  final HardwareWalletType hardwareWalletType;
  final TrezorConnectViewModelBase trezorConnectVM;

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

  /// The connect attempt this sheet was opened for (see
  /// [TrezorConnectViewModelBase.pairingAttempt]).
  Object? _attempt;

  /// Set once this sheet's attempt reached success, so its disposal (which
  /// only happens after the pop animation) never touches a later attempt.
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
      // A complete pairing code is submitted as soon as the last digit is
      // typed; the arrow button stays as a fallback.
      if (hasFullPin && !_pinSubmitted) {
        _submitPin();
      }
    });

    _attempt = widget.trezorConnectVM.pairingAttempt;
    _paringState = widget.trezorConnectVM.paringState;
    paringStateReaction = reaction((_) => widget.trezorConnectVM.paringState, (paringState) {
      if (paringState is SuccessTrezorParingState) {
        _finished = true;
        paringStateReaction?.reaction.dispose();
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      if (paringState is EnterPinTrezorParingState) {
        // A fresh code request (e.g. after a retry) needs a fresh submission.
        _pinSubmitted = false;
        _controller.text = "";
      }
      setState(() => _paringState = paringState);
    });
  }

  @override
  void dispose() {
    paringStateReaction?.reaction.dispose();
    // The sheet can be removed without its own buttons (e.g. the app locks and
    // the unlock navigation clears the route stack). A connect attempt that is
    // still pending must not stay parked forever behind a sheet that no
    // longer exists.
    final vm = widget.trezorConnectVM;
    if (!_finished && vm.isConnecting && vm.paringState is! SuccessTrezorParingState) {
      unawaited(vm.cancelPairing(attempt: _attempt));
    }
    super.dispose();
  }

  bool get _isAwaitingPin => _paringState == TrezorParingState.enterPin;

  bool _pinSubmitted = false;

  void _submitPin() {
    _pinSubmitted = true;
    widget.trezorConnectVM.setParingPin(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: SafeArea(
          bottom: false,
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  children: [
                    ModalTopBar(
                      title: "",
                      leadingWidget: AnimatedSwitcher(
                        layoutBuilder: (currentChild, previousChildren) => Stack(
                          alignment: Alignment.centerLeft,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        ),
                        duration: pinOpenDuration,
                        child: Text(
                          key: ValueKey(pageTitle),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                            // Lets the pending connect attempt clean up and
                            // report failure instead of waiting forever.
                            unawaited(widget.trezorConnectVM.cancelPairing(attempt: _attempt));
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: DirectionalAnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: content,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24, right: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(),
                          AnimatedOpacity(
                            curve: Curves.easeOutQuad,
                            opacity: hasFullPin ? 1 : 0,
                            duration: pinOpenDuration,
                            child: ModernButton(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              iconColor: Theme.of(context).colorScheme.onPrimary,
                              size: 36,
                              icon: const Icon(Icons.arrow_forward),
                              semanticLabel: S.of(context).confirm,
                              onPressed: _submitPin,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget get content => switch (_paringState) {
        InitialTrezorParingState() || EnterPinTrezorParingState() => PinEntryWidget(
            title: S.of(context).proceed_on_device,
            description: S.of(context).proceed_on_device_description,
            pinOpenDuration: pinOpenDuration,
            pinLength: pinLength,
            isAwaitingPin: _isAwaitingPin,
            controller: _controller,
            iconPath: hardwareWalletIcon ?? "",
            key: const ValueKey(0),
          ),
        VerifyingPinTrezorParingState() => const VerifyingProgressIndicator(
            key: ValueKey(1),
          ),
        FailTrezorParingState(:final message) => ConnectionErrorWidget(
            error: message,
            onRetryPressed: retry,
            key: const ValueKey(2),
          ),
        AwaitingSettingsTrezorParingState(
          :final isAutoPairingAvailable,
          :final passphraseAlwaysOnDevice,
        ) =>
          WalletOptionsScreen(
            trezorConnectVM: widget.trezorConnectVM,
            iconPath: hardwareWalletIcon ?? "",
            isAutoPairingAvailable: isAutoPairingAvailable,
            passphraseAlwaysOnDevice: passphraseAlwaysOnDevice,
            key: const ValueKey(3),
          ),
        AwaitingPassphraseTrezorParingState() => PinEntryWidget(
            title: S.of(context).passphrase_raw,
            description: S.of(context).trezor_step_passphrase_on_device,
            pinOpenDuration: pinOpenDuration,
            pinLength: pinLength,
            isAwaitingPin: false,
            controller: _controller,
            iconPath: hardwareWalletIcon ?? "",
            key: const ValueKey(4),
          ),
        AwaitingAppPassphraseTrezorParingState() => AppPassphraseEntryWidget(
            trezorConnectVM: widget.trezorConnectVM,
            key: const ValueKey(6),
          ),
        AwaitingAutoConnectConfirmTrezorParingState() => PinEntryWidget(
            title: S.of(context).auto_connect,
            description: S.of(context).trezor_step_autoconnect,
            pinOpenDuration: pinOpenDuration,
            pinLength: pinLength,
            isAwaitingPin: false,
            controller: _controller,
            iconPath: hardwareWalletIcon ?? "",
            key: const ValueKey(7),
          ),
        PairingOnDeviceTrezorParingState() => PinEntryWidget(
            title: S.of(context).proceed_on_device,
            description: S.of(context).trezor_step_pairing,
            pinOpenDuration: pinOpenDuration,
            pinLength: pinLength,
            isAwaitingPin: false,
            controller: _controller,
            iconPath: hardwareWalletIcon ?? "",
            key: const ValueKey(8),
          ),
        ConnectingTrezorParingState() => PinEntryWidget(
            title: S.of(context).proceed_on_device,
            description: S.of(context).trezor_step_connecting,
            pinOpenDuration: pinOpenDuration,
            pinLength: pinLength,
            isAwaitingPin: false,
            controller: _controller,
            iconPath: hardwareWalletIcon ?? "",
            key: const ValueKey(9),
          ),
        _ => const SizedBox.shrink(
            key: ValueKey(5),
          ),
      };

  void retry() {
    _controller.text = "";
    widget.trezorConnectVM.retryPairing();
  }

  String get pageTitle {
    if (_paringState is InitialTrezorParingState) {
      return S.of(context).device_confirmation;
    }

    if (_isAwaitingPin) {
      return S.of(context).pairing_code;
    }

    if (_paringState is AwaitingSettingsTrezorParingState) {
      return S.of(context).other_device_settings;
    }

    if (_paringState is AwaitingPassphraseTrezorParingState ||
        _paringState is AwaitingAppPassphraseTrezorParingState) {
      return S.of(context).passphrase_entry;
    }

    if (_paringState is AwaitingAutoConnectConfirmTrezorParingState) {
      return S.of(context).auto_connect;
    }

    if (_paringState is PairingOnDeviceTrezorParingState ||
        _paringState is ConnectingTrezorParingState) {
      return S.of(context).device_confirmation;
    }

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
}

class ConnectionErrorWidget extends StatelessWidget {
  const ConnectionErrorWidget({required this.error, required this.onRetryPressed, super.key});

  final VoidCallback onRetryPressed;
  final String error;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: key,
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
                error,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              NewPrimaryButton(
                onPressed: onRetryPressed,
                text: S.of(context).try_again,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ],
          ),
        ),
      );
}

class VerifyingProgressIndicator extends StatelessWidget {
  const VerifyingProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        key: key,
        width: MediaQuery.of(context).size.width,
        child: Column(
          spacing: 12,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CupertinoActivityIndicator(radius: 36),
            const SizedBox(),
            Text(
              "${S.of(context).verifying_code}...",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
            ),
            Text(
              S.of(context).this_can_take_few_seconds,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

class PinEntryWidget extends StatelessWidget {
  const PinEntryWidget({
    required this.pinOpenDuration,
    required this.pinLength,
    required this.controller,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isAwaitingPin,
    super.key,
  });

  final DigitInputController controller;
  final String iconPath;
  final bool isAwaitingPin;
  final int pinLength;
  final Duration pinOpenDuration;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        key: key,
        spacing: 12,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: pinOpenDuration,
            curve: Curves.easeOutCubic,
            width: isAwaitingPin ? 40 : 100,
            height: isAwaitingPin ? 40 : 100,
            child: CakeImageWidget(
              imageUrl: iconPath,
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
            child: isAwaitingPin
                ? Column(
                    spacing: 24,
                    key: const ValueKey(1),
                    children: [
                      Text(
                        textAlign: TextAlign.center,
                        "${S.of(context).pairing_code_desc_1}\n${S.of(context).pairing_code_desc_2}",
                      ),
                      DigitInput(
                        controller: controller,
                        desiredLength: pinLength,
                      ),
                    ],
                  )
                : Column(
                    key: const ValueKey(0),
                    spacing: 12,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      );
}

/// Passphrase field for a wallet set up with an app-side passphrase. Uses the
/// same field, illustration and reveal toggle as the hot-wallet passphrase
/// sheet (AddPassphraseBottomSheet). The value goes straight to the view model
/// for this session and is not kept.
class AppPassphraseEntryWidget extends StatefulWidget {
  const AppPassphraseEntryWidget({
    required this.trezorConnectVM,
    super.key,
  });

  final TrezorConnectViewModelBase trezorConnectVM;

  @override
  State<AppPassphraseEntryWidget> createState() => _AppPassphraseEntryWidgetState();
}

class _AppPassphraseEntryWidgetState extends State<AppPassphraseEntryWidget> {
  final _controller = TextEditingController();
  bool _obscurePassphrase = true;

  static const _passphraseImageLight = "assets/images/passphrase_light.png";
  static const _passphraseImageDark = "assets/images/passphrase_dark.png";

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.trezorConnectVM.setPassphrase(_controller.text);

  @override
  Widget build(BuildContext context) {
    final passphraseImage =
        context.currentTheme.isDark ? _passphraseImageDark : _passphraseImageLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          CakeImageWidget(imageUrl: passphraseImage, height: 85),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              S.of(context).trezor_step_passphrase_in_app,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    decoration: TextDecoration.none,
                  ),
            ),
          ),
          const SizedBox(height: 24),
          BaseTextFormField(
            key: const ValueKey("trezor_app_passphrase_textfield_key"),
            controller: _controller,
            obscureText: _obscurePassphrase,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            onSubmit: (_) => _submit(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            hintText: S.of(context).required_passphrase,
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscurePassphrase = !_obscurePassphrase),
              child: Icon(
                _obscurePassphrase ? Icons.visibility_off : Icons.visibility,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 24),
          NewPrimaryButton(
            key: const ValueKey("trezor_app_passphrase_continue_button_key"),
            onPressed: _submit,
            text: S.of(context).continue_text,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class WalletOptionsScreen extends StatefulWidget {
  const WalletOptionsScreen({
    required this.trezorConnectVM,
    required this.isAutoPairingAvailable,
    required this.passphraseAlwaysOnDevice,
    required this.iconPath,
    super.key,
  });

  final String iconPath;
  final TrezorConnectViewModelBase trezorConnectVM;
  final bool isAutoPairingAvailable;

  /// The device always asks for the passphrase on its own screen, so the
  /// passphrase options are not offered here.
  final bool passphraseAlwaysOnDevice;

  @override
  State<WalletOptionsScreen> createState() => _WalletOptionsScreenState();
}

class _WalletOptionsScreenState extends State<WalletOptionsScreen> {
  bool _autoConnect = true;
  bool _usePassphrase = false;
  bool _setPassphraseOnDevice = true;
  final _passphraseController = TextEditingController();

  bool get _showPassphraseOptions => !widget.passphraseAlwaysOnDevice;

  bool get anythingSelected =>
      (_autoConnect && widget.isAutoPairingAvailable) || (_usePassphrase && _showPassphraseOptions);

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 32,
                children: [
                  Column(
                    spacing: 12,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 116,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: CakeImageWidget(
                                imageUrl: widget.iconPath,
                                width: 100,
                                height: 100,
                                colorFilter: ColorFilter.mode(
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 0,
                              bottom: 0,
                              child: BorderedSvgIcon(
                                iconPath: "assets/new-ui/cog.svg",
                                iconSize: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox.shrink(),
                      Text(
                        S.of(context).almost_ready,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        S.of(context).hww_options_desc,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  NewListSections(
                    sections: {
                      if (widget.isAutoPairingAvailable)
                        "auto": [
                          ListItemToggle(
                            value: _autoConnect,
                            onChanged: (val) => setState(() => _autoConnect = val),
                            keyValue: "autoconnect",
                            label: S.of(context).auto_connect,
                            subtitle: S.of(context).auto_connect_desc,
                          ),
                        ],
                      if (_showPassphraseOptions)
                        "pass": [
                          ListItemToggle(
                            value: _usePassphrase,
                            onChanged: (val) => setState(() => _usePassphrase = val),
                            keyValue: "passphrase",
                            label: S.of(context).passphrase,
                            subtitle: S.of(context).wallet_has_passphrase,
                          ),
                          if (_usePassphrase) ...[
                            ListItemToggle(
                              value: _setPassphraseOnDevice,
                              onChanged: (val) => setState(() => _setPassphraseOnDevice = val),
                              keyValue: "passphrase on device",
                              label: S.of(context).enter_passphrase_on_device,
                            ),
                            if (!_setPassphraseOnDevice)
                              ListItemRegularRow(
                                keyValue: "passphrase on app",
                                label: S.of(context).passphrase_raw,
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => MoneroHardwareWalletPassphraseInputModal(
                                      controller: _passphraseController,
                                    ),
                                  );
                                },
                              ),
                          ]
                        ],
                    },
                  ),
                ],
              ),
            ),
            NewPrimaryButton(
              onPressed: () => widget.trezorConnectVM.setDeviceSettings(
                TrezorDeviceSettings(
                  enableAutoParing: _autoConnect,
                  passphraseOnDevice: _usePassphrase && _setPassphraseOnDevice,
                  passphrase:
                      _usePassphrase && !_setPassphraseOnDevice ? _passphraseController.text : null,
                ),
              ),
              text: anythingSelected ? S.of(context).continue_text : S.of(context).skip,
              color: anythingSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              textColor: anythingSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
}
