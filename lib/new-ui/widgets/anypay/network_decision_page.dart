import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/material.dart";

class NetworkDecisionPage extends StatelessWidget {
  const NetworkDecisionPage({
    required this.title,
    required this.description,
    required this.destinationIconPath,
    required this.primaryText,
    required this.onPrimary,
    required this.secondaryText,
    this.currentIconPath,
    this.primaryIconPath,
    this.secondaryIconPath,
    this.onSecondary,
    super.key,
  });

  final String title;
  final String description;
  final String destinationIconPath;
  final String? currentIconPath;
  final String primaryText;
  final VoidCallback onPrimary;
  final String? primaryIconPath;
  final String secondaryText;
  final String? secondaryIconPath;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primaryIcon = primaryIconPath;
    final secondaryIcon = secondaryIconPath;
    return Material(
      color: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            ModalTopBar(
              title: "",
              leadingIcon: const Icon(Icons.arrow_back_ios_new),
              leadingSemanticLabel: S.of(context).seed_alert_back,
              onLeadingPressed: () => Navigator.of(context).maybePop(),
              trailingIcon: const Icon(Icons.close),
              trailingSemanticLabel: S.of(context).close,
              onTrailingPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: _DecisionHeader(
                          destinationIconPath: destinationIconPath,
                          currentIconPath: currentIconPath,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant, letterSpacing: -0.07),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NewPrimaryButton(
                    onPressed: onPrimary,
                    image: primaryIcon != null
                        ? CakeImageWidget(
                            imageUrl: primaryIcon,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(colors.onPrimary, BlendMode.srcIn),
                          )
                        : null,
                    text: primaryText,
                    color: colors.primary,
                    textColor: colors.onPrimary,
                  ),
                  const SizedBox(height: 12),
                  NewPrimaryButton(
                    onPressed: onSecondary ?? () => Navigator.of(context).maybePop(),
                    image: secondaryIcon != null
                        ? CakeImageWidget(
                            imageUrl: secondaryIcon,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                          )
                        : null,
                    text: secondaryText,
                    color: colors.surfaceContainer,
                    textColor: colors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecisionHeader extends StatelessWidget {
  const _DecisionHeader({required this.destinationIconPath, this.currentIconPath});

  final String destinationIconPath;
  final String? currentIconPath;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final current = currentIconPath;

    if (current == null) {
      return CakeImageWidget(
        imageUrl: destinationIconPath,
        width: 75,
        height: 75,
        fit: BoxFit.contain,
        color: isMonochromeSymbolIcon(destinationIconPath) ? colors.primary : null,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        CakeImageWidget(
          imageUrl: current,
          width: 50,
          height: 50,
          fit: BoxFit.contain,
          color: isMonochromeSymbolIcon(current) ? colors.primary : null,
        ),
        Icon(Icons.arrow_forward, color: colors.primary, size: 28),
        CakeImageWidget(
          imageUrl: destinationIconPath,
          width: 50,
          height: 50,
          fit: BoxFit.contain,
          color: isMonochromeSymbolIcon(destinationIconPath) ? colors.primary : null,
        ),
      ],
    );
  }
}
