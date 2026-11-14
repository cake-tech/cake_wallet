import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:flutter/material.dart";

class HardwareWalletBitboxParingSheet extends StatelessWidget {
  const HardwareWalletBitboxParingSheet({required this.paringCode, super.key});

  final String paringCode;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModalTopBar(
                title: S.of(context).pairing_code,
                onLeadingPressed: () => Navigator.of(context).pop(false),
                onTrailingPressed: () {},
                leadingIcon: const Icon(Icons.close),
                leadingSemanticLabel: S.of(context).close,
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    const SizedBox(),
                    Text(
                      S.of(context).pairing_code_bitbox_confirm,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SelectableText(
                        paringCode,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: "IBM Plex Mono",
                          letterSpacing: 2,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(),
                    NewPrimaryButton(
                      text: S.of(context).continue_text,
                      onPressed: () => Navigator.of(context).pop(true),
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
