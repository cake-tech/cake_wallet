import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/copy_wrapper.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class ReceiveBottomButtons extends StatefulWidget {
  const ReceiveBottomButtons({
    required this.largeQrMode,
    required this.onCopyButtonPressed,
    required this.onAccountsButtonPressed,
    required this.onAmountButtonPressed,
    required this.onLabelButtonPressed,
    required this.showLabelButton,
    required this.showAccountsButton,
    required this.copyData,
    super.key,
  });

  final bool largeQrMode;
  final ClipboardData? copyData;
  final VoidCallback onCopyButtonPressed;
  final VoidCallback onAmountButtonPressed;
  final VoidCallback onLabelButtonPressed;
  final VoidCallback onAccountsButtonPressed;
  final bool showLabelButton;
  final bool showAccountsButton;

  @override
  State<ReceiveBottomButtons> createState() => _ReceiveBottomButtonsState();
}

class _ReceiveBottomButtonsState extends State<ReceiveBottomButtons> {
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                // The button itself is the only control: it copies when there
                // is data to copy, otherwise it opens the payjoin copy modal.
                CopyWrapper(
                  data: widget.copyData,
                  controlBuilder: (context, copied, onCopy) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: ModernButton.svg(
                      key: ValueKey(copied),
                      size: 60,
                      iconSize: 32,
                      svgPath: "assets/new-ui/copy.svg",
                      onPressed: onCopy ?? widget.onCopyButtonPressed,
                      label: copied ? S.of(context).copied : S.of(context).copy,
                      iconColor: copied
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceContainer,
                      backgroundColor: copied
                          ? Theme.of(context).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                ModernButton.svg(
                  size: 60,
                  iconSize: 32,
                  svgPath: "assets/new-ui/set-amount.svg",
                  onPressed: widget.onAmountButtonPressed,
                  label: S.of(context).set_amount,
                ),
                if (widget.showLabelButton)
                  ModernButton.svg(
                    size: 60,
                    iconSize: 32,
                    svgPath: "assets/new-ui/add-label.svg",
                    onPressed: widget.onLabelButtonPressed,
                    label: S.of(context).label,
                  ),
                if (widget.showAccountsButton)
                  ModernButton.svg(
                    size: 60,
                    iconSize: 32,
                    svgPath: "assets/new-ui/addr-book.svg",
                    onPressed: widget.onAccountsButtonPressed,
                    label: S.of(context).addresses,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
