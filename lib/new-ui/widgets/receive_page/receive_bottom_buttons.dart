import 'dart:io';

import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';

class ReceiveBottomButtons extends StatefulWidget {
  final bool largeQrMode;
  final VoidCallback onCopyButtonPressed;
  final VoidCallback onAmountButtonPressed;
  final VoidCallback onLabelButtonPressed;
  final VoidCallback onAccountsButtonPressed;
  final bool showLabelButton;
  final bool showAccountsButton;

  const ReceiveBottomButtons({
    super.key,
    required this.largeQrMode,
    required this.onCopyButtonPressed,
    required this.onAccountsButtonPressed,
    required this.onAmountButtonPressed,
    required this.onLabelButtonPressed,
    required this.showLabelButton,
    required this.showAccountsButton,
  });

  @override
  State<ReceiveBottomButtons> createState() => _ReceiveBottomButtonsState();
}

class _ReceiveBottomButtonsState extends State<ReceiveBottomButtons> {
  bool copied = false;

  void handleCopy() async {
    widget.onCopyButtonPressed();
    if (await shouldShowCopied()) {
      setState(() => copied = true);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double targetOpacity = widget.largeQrMode ? 0 : 1;

    return ClipRect(
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        heightFactor: widget.largeQrMode ? 0 : 1,
        alignment: Alignment.bottomCenter,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: targetOpacity,
          curve: Curves.easeOut,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 200),
                  child: ModernButton.svg(
                    key: ValueKey(copied),
                    size: 60,
                    iconSize: 32,
                    svgPath: "assets/new-ui/copy.svg",
                    onPressed: handleCopy,
                    label: copied ? S.of(context).copied : S.of(context).copy,
                    iconColor: copied ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainer,
                    backgroundColor: copied ? Theme.of(context).colorScheme.surfaceContainerHighest : Theme.of(context).colorScheme.primary,
                  ),
                ),
                ModernButton.svg(
                    size: 60,
                    iconSize: 32,
                    svgPath: "assets/new-ui/set-amount.svg",
                    onPressed: widget.onAmountButtonPressed,
                    label: S.of(context).set_amount),
                if (widget.showLabelButton)
                  ModernButton.svg(
                      size: 60,
                      iconSize: 32,
                      svgPath: "assets/new-ui/add-label.svg",
                      onPressed: widget.onLabelButtonPressed,
                      label: S.of(context).label),
                if (widget.showAccountsButton)
                  ModernButton.svg(
                      size: 60,
                      iconSize: 32,
                      svgPath: "assets/new-ui/addr-book.svg",
                      onPressed: widget.onAccountsButtonPressed,
                      label: S.of(context).addresses),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // android 13 (sdk 33) added a built-in "text was copied to clipboard" ui element
  // older android and iphone still needs an indicator though
  Future<bool> shouldShowCopied() async {
    if (!Platform.isAndroid) return true;

    try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdk = androidInfo.version.sdkInt;
    
        return sdk < 33;
    } catch (_) {
        return true;
    }
  }
}