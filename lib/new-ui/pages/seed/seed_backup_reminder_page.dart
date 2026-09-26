import "package:cake_wallet/core/auth_service.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/seed/dismiss_seed_verification_page.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_hero_image.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_header.dart";
import "package:cake_wallet/new-ui/widgets/seed/seed_page_scaffold.dart";
import "package:cake_wallet/new-ui/widgets/stacked_buttons.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class SeedBackupReminderPage extends StatelessWidget {
  const SeedBackupReminderPage({
    required this.dashboardViewModel,
    required this.authService,
    super.key,
  });

  final DashboardViewModel dashboardViewModel;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => SeedPageScaffold(
        content: SeedPageHeader(
          image: const SeedHeroImage(),
          title: S.of(context).recovery_phrase_intro_title,
          description: Text(
            S.of(context).recovery_phrase_intro_description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: -0.07,
                ),
          ),
        ),
        footer: StackedButtons(
          primaryKey: const ValueKey("seed_backup_reminder_page_button_key"),
          primaryText: S.of(context).show_recovery_phrase,
          onPrimary: () => authService.authenticateAction(
            context,
            route: Routes.seed,
            arguments: false,
            conditionToDetermineIfToUse2FA: dashboardViewModel
                .settingsStore.shouldRequireTOTP2FAForAllSecurityAndBackupSettings,
          ),
          secondaryKey: const ValueKey("seed_backup_reminder_page_dismiss_button_key"),
          secondaryText: S.of(context).dismiss_this_step,
          onSecondary: () => Navigator.of(context).push(
            CupertinoPageRoute<void>(
              builder: (_) => DismissSeedVerificationPage(onConfirm: () => _dismiss(context)),
            ),
          ),
          secondaryAsLink: true,
        ),
      );

  Future<void> _dismiss(BuildContext context) async {
    await dashboardViewModel.dismissSeedBackupReminder();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
