import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_hero_image.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_header.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/stacked_buttons.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:flutter/material.dart";

class ShowKeysDisclaimerPage extends StatelessWidget {
  const ShowKeysDisclaimerPage({
    required this.authService,
    required this.settingsStore,
    super.key,
  });

  final AuthService authService;
  final SettingsStore settingsStore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SeedPageScaffold(
      content: SeedPageHeader(
        image: const SeedHeroImage(showWarningBadge: true),
        title: S.of(context).secret_information_ahead,
        description: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: "${S.of(context).secret_information_ahead_description}\n\n"),
              TextSpan(
                text: S.of(context).secret_information_ahead_warning,
                style: TextStyle(color: context.customColors.warningOutlineColor),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
                letterSpacing: -0.07,
              ),
        ),
      ),
      footer: StackedButtons(
        primaryKey: const ValueKey("show_keys_disclaimer_page_button_key"),
        primaryText: S.of(context).show_recovery_phrase_and_keys,
        onPrimary: () => authService.authenticateAction(
          context,
          route: Routes.showKeys,
          conditionToDetermineIfToUse2FA:
              settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
        ),
        secondaryKey: const ValueKey("show_keys_disclaimer_page_back_button_key"),
        secondaryText: S.of(context).seed_alert_back,
        onSecondary: () => Navigator.of(context).pop(),
      ),
    );
  }
}
