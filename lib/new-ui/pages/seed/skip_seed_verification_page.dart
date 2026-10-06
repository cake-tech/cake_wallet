import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_header.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/stacked_buttons.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";

class SkipSeedVerificationPage extends StatelessWidget {
  const SkipSeedVerificationPage({required this.onConfirm, super.key});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => SeedPageScaffold(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 295),
          child: SeedPageHeader(
            image: const CakeImageWidget(
              imageUrl: "assets/new-ui/warning_triangle.svg",
              width: 125,
              height: 111.72,
            ),
            imageSpacing: 48,
            titleSpacing: 24,
            title: S.of(context).skip_verification_title,
            description: Column(
              spacing: 24,
              children: [
                Text(
                  S.of(context).skip_verification_warning,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.customColors.warningOutlineColor,
                        letterSpacing: -0.07,
                      ),
                ),
                Text(
                  S.of(context).skip_verification_question,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        letterSpacing: -0.07,
                      ),
                ),
              ],
            ),
          ),
        ),
        footer: StackedButtons(
          primaryKey: const ValueKey("skip_seed_verification_page_confirm_button_key"),
          primaryText: S.of(context).skip_verification_confirm,
          onPrimary: onConfirm,
          secondaryKey: const ValueKey("skip_seed_verification_page_back_button_key"),
          secondaryText: S.of(context).seed_alert_back,
          onSecondary: () => Navigator.of(context).pop(),
        ),
      );
}
