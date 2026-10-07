import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";

class ZcashManualShieldModal extends StatelessWidget {
  const ZcashManualShieldModal({required this.balance, required this.onShield, super.key});

  final String balance;
  final VoidCallback onShield;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                ModalTopBar(
                  title: S.of(context).shield_device_funds,
                  trailingIcon: const Icon(Icons.close),
                  onTrailingPressed: Navigator.of(context).pop,
                  trailingSemanticLabel: S.of(context).close,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16,
                          children: [
                            Icon(
                              Icons.visibility,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            Icon(
                              Icons.arrow_forward,
                              size: 32,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            Icon(
                              Icons.shield_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildUnshieldedHeadline(context),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: context.customColors.warningContainerColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 8,
                            children: [
                              const CakeImageWidget(
                                imageUrl: "assets/new-ui/crypto_full_icons/zcash.svg",
                                height: 24,
                                width: 24,
                              ),
                              Text(
                                balance,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: context.customColors.warningOutlineColor,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          S.of(context).why_is_shielding_needed,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        _InfoCard(text: S.of(context).unshielded_funds_transparent_desc),
                        const SizedBox(height: 12),
                        _InfoCard(text: S.of(context).shielded_only_sends_desc),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    spacing: 12,
                    children: [
                      Text(
                        S.of(context).do_you_want_to_proceed,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      NewPrimaryButton(
                        onPressed: Navigator.of(context).pop,
                        text: S.of(context).cancel,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        textColor: Theme.of(context).colorScheme.primary,
                      ),
                      NewPrimaryButton(
                        onPressed: onShield,
                        text: S.of(context).shield_funds,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildUnshieldedHeadline(BuildContext context) {
    const marker = "\u0000";
    final parts = S.of(context).wallet_holds_unshielded_zec(marker).split(marker);

    return Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 14),
        children: [
          TextSpan(text: parts.first),
          TextSpan(
            text: S.of(context).unshielded,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
          TextSpan(text: parts.last),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      );
}
