import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/dashboard/dashboard_view_model.dart";
import "package:flutter/material.dart";
import "package:flutter_mobx/flutter_mobx.dart";

class SeedBackupReminderCard extends StatelessWidget {
  const SeedBackupReminderCard({required this.dashboardViewModel, required this.onTap, super.key});

  final DashboardViewModel dashboardViewModel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Observer(
        builder: (_) {
          if (!dashboardViewModel.shouldShowSeedBackupReminder) {
            return const SizedBox.shrink();
          }

          final colors = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 24),
            child: MergeSemantics(
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: CakeImageWidget(
                            imageUrl: "assets/new-ui/key.svg",
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 4,
                            children: [
                              Text(
                                S.of(context).back_up_recovery_phrase,
                                style: textTheme.labelLarge?.copyWith(
                                  color: colors.onSurface,
                                  letterSpacing: -0.07,
                                ),
                              ),
                              Text(
                                S.of(context).back_up_recovery_phrase_description,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: -0.06,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 16, color: colors.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
}
